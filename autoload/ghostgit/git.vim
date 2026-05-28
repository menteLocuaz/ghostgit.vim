" ============================================================================
" ghostgit.vim - Git Command Wrappers
" ============================================================================

function! ghostgit#git#Status(...) abort
  let l:cwd = get(a:000, 0, '')
  return ghostgit#core#Run(['status', '--short', '--branch'], l:cwd)
endfunction

function! ghostgit#git#Add(file, ...) abort
  let l:cwd = get(a:000, 0, '')
  return ghostgit#core#Run(['add', '--', a:file], l:cwd)
endfunction

function! ghostgit#git#Reset(file, ...) abort
  let l:cwd = get(a:000, 0, '')
  return ghostgit#core#Run(['reset', 'HEAD', '--', a:file], l:cwd)
endfunction

function! ghostgit#git#Diff(file, ...) abort
  let l:extra_args = get(a:000, 0, '')
  let l:cwd = get(a:000, 1, '')
  let l:args = ['diff']

  if !empty(l:extra_args)
    call add(l:args, l:extra_args)
  endif

  call add(l:args, '--')
  call add(l:args, a:file)
  return ghostgit#core#Run(l:args, l:cwd)
endfunction
