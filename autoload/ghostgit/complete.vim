" ============================================================================
" ghostgit.vim - Git Command Completion for :Git and :G
" ============================================================================

function! ghostgit#complete#Complete(A, L, P) abort
  let l:args = split(a:L)
  let l:subcmd = get(l:args, 1, '')

  if len(l:args) <= 1
    return ghostgit#complete#Subcommands()
  endif

  return ghostgit#complete#Context(l:subcmd)
endfunction

function! ghostgit#complete#Subcommands() abort
  return ['add', 'bisect', 'branch', 'checkout', 'clone', 'commit',
        \ 'diff', 'fetch', 'grep', 'init', 'log', 'merge', 'mv', 'pull',
        \ 'push', 'rebase', 'reset', 'restore', 'rm', 'show', 'status',
        \ 'stash', 'switch', 'tag']
endfunction

function! ghostgit#complete#Context(subcmd) abort
  if a:subcmd =~# '^\(checkout\|switch\|branch\|merge\|rebase\|log\|show\)$'
    return ghostgit#complete#Branches()
  elseif a:subcmd =~# '^\(add\|restore\)$'
    return ghostgit#complete#ModifiedFiles()
  elseif a:subcmd ==# 'reset'
    return ghostgit#complete#StagedFiles()
  elseif a:subcmd ==# 'diff'
    return ghostgit#complete#Branches() + ghostgit#complete#ModifiedFiles()
  elseif a:subcmd ==# 'remote'
    return ghostgit#complete#Remotes()
  elseif a:subcmd ==# 'tag'
    return ghostgit#complete#Tags()
  elseif a:subcmd =~# '^\(rm\|mv\)$'
    return ghostgit#complete#TrackedFiles()
  elseif a:subcmd ==# 'stash'
    return ghostgit#complete#Stashes()
  endif

  return []
endfunction

function! ghostgit#complete#Branches() abort
  let l:root = ghostgit#core#RepoRoot()
  if empty(l:root) | return [] | endif

  let l:local = ghostgit#core#Run(['branch', '--format', '%(refname:short)'], l:root)
  let l:remote = ghostgit#core#Run(['branch', '-r', '--format', '%(refname:short)'], l:root)

  return l:local + l:remote
endfunction

function! ghostgit#complete#ModifiedFiles() abort
  let l:root = ghostgit#core#RepoRoot()
  if empty(l:root) | return [] | endif

  let l:files = []
  for l:line in ghostgit#core#Run(['status', '--porcelain'], l:root)
    if len(l:line) > 3
      call add(l:files, l:line[3:])
    endif
  endfor

  return l:files
endfunction

function! ghostgit#complete#StagedFiles() abort
  let l:root = ghostgit#core#RepoRoot()
  if empty(l:root) | return [] | endif

  return ghostgit#core#Run(['diff', '--name-only', '--cached'], l:root)
endfunction

function! ghostgit#complete#Remotes() abort
  let l:root = ghostgit#core#RepoRoot()
  if empty(l:root) | return [] | endif

  return ghostgit#core#Run(['remote'], l:root)
endfunction

function! ghostgit#complete#Tags() abort
  let l:root = ghostgit#core#RepoRoot()
  if empty(l:root) | return [] | endif

  return ghostgit#core#Run(['tag'], l:root)
endfunction

function! ghostgit#complete#TrackedFiles() abort
  let l:root = ghostgit#core#RepoRoot()
  if empty(l:root) | return [] | endif

  return ghostgit#core#Run(['ls-files'], l:root)
endfunction

function! ghostgit#complete#Stashes() abort
  let l:root = ghostgit#core#RepoRoot()
  if empty(l:root) | return [] | endif

  return ghostgit#core#Run(['stash', 'list', '--format', '%gd: %gs'], l:root)
endfunction
