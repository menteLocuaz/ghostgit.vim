" ============================================================================
" ghostgit.vim - Core Git API test
" ============================================================================

let s:assert = themis#helper('assert')

" ---------------------------------------------------------------------------
" Helpers
" ---------------------------------------------------------------------------

function! s:setup_repo() abort
  let l:d = tempname()
  call mkdir(l:d, 'p')
  call systemlist(['git', '-C', l:d, 'init', '-b', 'main'])
  call systemlist(['git', '-C', l:d, 'config', 'user.email', 'test@test.com'])
  call systemlist(['git', '-C', l:d, 'config', 'user.name', 'test'])
  call systemlist(['git', '-C', l:d, 'commit', '--allow-empty', '-m', 'init'])
  return l:d
endfunction

function! s:cleanup(d) abort
  if isdirectory(a:d)
    call delete(a:d, 'rf')
  endif
endfunction

" ---------------------------------------------------------------------------
" Suite
" ---------------------------------------------------------------------------

describe 'ghostgit#core'
  before
    let s:repo = s:setup_repo()
    let s:plain = tempname()
    call mkdir(s:plain, 'p')
    let s:cwd_saved = getcwd()
  end

  after
    call s:cleanup(s:repo)
    call s:cleanup(s:plain)
    execute 'cd ' . fnameescape(s:cwd_saved)
  end

  " =======================================================================
  " ghostgit#core#Run
  " =======================================================================

  it 'runs git command with list args'
    let l:result = ghostgit#core#Run(['rev-parse', '--show-toplevel'], s:repo)
    call s:assert.equals(l:result[0], s:repo)
  end

  it 'runs git command with string arg'
    let l:result = ghostgit#core#Run('status', s:repo)
    call s:assert.is_not_empty(l:result)
  end

  it 'returns empty list on failure'
    let l:result = ghostgit#core#Run(['rev-parse', '--show-toplevel'], s:plain)
    call s:assert.equals(l:result, [])
  end

  it 'defaults cwd to getcwd()'
    execute 'cd ' . fnameescape(s:repo)
    let l:result = ghostgit#core#Run(['rev-parse', '--show-toplevel'])
    call s:assert.equals(l:result[0], s:repo)
  end

  " =======================================================================
  " ghostgit#core#RepoRoot
  " =======================================================================

  it 'RepoRoot returns repo root'
    let l:result = ghostgit#core#RepoRoot()
    let l:saved = getcwd()
    execute 'cd ' . fnameescape(s:repo)
    let l:result = ghostgit#core#RepoRoot()
    call s:assert.equals(l:result, s:repo)
    execute 'cd ' . fnameescape(l:saved)
  end

  it 'RepoRoot returns empty string outside repo'
    let l:saved = getcwd()
    execute 'cd ' . fnameescape(s:plain)
    let l:result = ghostgit#core#RepoRoot()
    call s:assert.equals(l:result, '')
    execute 'cd ' . fnameescape(l:saved)
  end

  " =======================================================================
  " ghostgit#core#CurrentBranch
  " =======================================================================

  it 'CurrentBranch returns branch name'
    let l:result = ghostgit#core#CurrentBranch(s:repo)
    call s:assert.equals(l:result, 'main')
  end

  it 'CurrentBranch returns empty string outside repo'
    let l:result = ghostgit#core#CurrentBranch(s:plain)
    call s:assert.equals(l:result, '')
  end

  it 'CurrentBranch accepts optional cwd'
    let l:in_repo  = ghostgit#core#CurrentBranch(s:repo)
    let l:in_plain = ghostgit#core#CurrentBranch(s:plain)
    call s:assert.equals(l:in_repo, 'main')
    call s:assert.equals(l:in_plain, '')
  end

  " =======================================================================
  " ghostgit#core#IsRepo
  " =======================================================================

  it 'IsRepo returns 1 inside a repo'
    call s:assert.true(ghostgit#core#IsRepo(s:repo))
  end

  it 'IsRepo returns 0 outside a repo'
    call s:assert.false(ghostgit#core#IsRepo(s:plain))
  end

  it 'IsRepo accepts optional cwd'
    call s:assert.true(ghostgit#core#IsRepo(s:repo))
    call s:assert.false(ghostgit#core#IsRepo(s:plain))
  end
end
