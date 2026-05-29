" ============================================================================
" ghostgit.vim - Test Git Setup Helpers
" ============================================================================

let s:test_counter = 0

function! ghostgit#test#Setup() abort
  let s:test_counter += 1
  let l:dir = tempname() . s:test_counter
  call mkdir(l:dir, 'p')
  call systemlist(['git', '-C', l:dir, 'init', '-b', 'main'])
  call systemlist(['git', '-C', l:dir, 'config', 'user.email', 'test@ghostgit.dev'])
  call systemlist(['git', '-C', l:dir, 'config', 'user.name', 'GhostGit Test'])
  call systemlist(['git', '-C', l:dir, 'config', 'core.quotePath', 'false'])
  call systemlist(['git', '-C', l:dir, 'commit', '--allow-empty', '-m', 'initial commit'])
  return l:dir
endfunction

function! ghostgit#test#SetupEmptyRepo() abort
  let s:test_counter += 1
  let l:dir = tempname() . s:test_counter
  call mkdir(l:dir, 'p')
  call systemlist(['git', '-C', l:dir, 'init', '-b', 'main'])
  call systemlist(['git', '-C', l:dir, 'config', 'user.email', 'test@ghostgit.dev'])
  call systemlist(['git', '-C', l:dir, 'config', 'user.name', 'GhostGit Test'])
  call systemlist(['git', '-C', l:dir, 'config', 'core.quotePath', 'false'])
  return l:dir
endfunction

function! ghostgit#test#CreateFile(dir, path, content) abort
  let l:full = a:dir . '/' . a:path
  let l:parent = fnamemodify(l:full, ':h')
  if !isdirectory(l:parent)
    call mkdir(l:parent, 'p')
  endif
  call writefile(split(a:content, "\n", 1), l:full)
endfunction

function! ghostgit#test#StageFile(dir, path) abort
  call systemlist(['git', '-C', a:dir, 'add', '--', a:path])
endfunction

function! ghostgit#test#Teardown(dir) abort
  if isdirectory(a:dir)
    call delete(a:dir, 'rf')
  endif
endfunction
