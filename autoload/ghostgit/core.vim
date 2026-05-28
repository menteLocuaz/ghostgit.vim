" ============================================================================
" ghostgit.vim - Core Git API
" ============================================================================

" Run a git command and return output
function! ghostgit#core#Run(args, ...) abort
  let l:cwd = get(a:000, 0, getcwd())

  if type(a:args) == v:t_list
    let l:cmd = ['git'] + a:args
  else
    let l:cmd = ['git', a:args]
  endif

  let l:output = systemlist(l:cmd, '', {'cwd': l:cwd})
  let l:exit = v:shell_error

  if l:exit != 0
    call ghostgit#util#Error(join(l:output, "\n"))
    return []
  endif

  return l:output
endfunction


" Return root from current repo
function! ghostgit#core#RepoRoot() abort
  let l:result = ghostgit#core#Run([
        \ 'rev-parse',
        \ '--show-toplevel'
        \ ])

  return empty(l:result) ? '' : l:result[0]
endfunction


" Return current branch
function! ghostgit#core#CurrentBranch(...) abort
  let l:cwd    = get(a:000, 0, '')
  let l:result = ghostgit#core#Run(['rev-parse', '--abbrev-ref', 'HEAD'], l:cwd)
  return empty(l:result) ? '' : l:result[0]
endfunction


function! ghostgit#core#IsRepo(...) abort
  let l:cwd = get(a:000, 0, '')
  let l:cmd = 'git rev-parse --git-dir'
  if !empty(l:cwd)
    let l:cmd = 'cd ' . shellescape(l:cwd) . ' && ' . l:cmd
  endif
  call systemlist(l:cmd)
  return v:shell_error == 0
endfunction
