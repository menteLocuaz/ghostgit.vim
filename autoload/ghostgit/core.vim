" ============================================================================
" ghostgit.vim - Core Git API
" ============================================================================

" Run a git command and return output
function! ghostgit#core#Run(args, ...) abort
  let l:cwd = get(a:000, 0, '')
  if empty(l:cwd)
    let l:cwd = getcwd()
  endif

  if type(a:args) == v:t_list
    let l:cmd = ['git'] + a:args
  else
    let l:cmd = ['git', a:args]
  endif

  let l:saved_cwd = getcwd()
  execute 'cd ' . fnameescape(l:cwd)
  let l:output = systemlist(l:cmd)
  let l:exit = v:shell_error
  execute 'cd ' . fnameescape(l:saved_cwd)

  if l:exit != 0
    call ghostgit#util#Error(join(l:output, "\n"))
    return []
  endif

  return l:output
endfunction


" Return root from current repo
function! ghostgit#core#RepoRoot(...) abort
  let l:cwd = get(a:000, 0, '')
  let l:entry = ghostgit#state#GetRepo(l:cwd)
  if !empty(l:entry) && !empty(l:entry.git_dir)
    return l:entry.git_dir
  endif

  let l:result = ghostgit#core#Run(['rev-parse', '--show-toplevel'], l:cwd)
  if !empty(l:result)
    let l:root = l:result[0]
    call ghostgit#state#SetRepo(l:root)
    let g:ghostgit_state.repos[l:root].git_dir = l:root
    return l:root
  endif

  return ''
endfunction


" Return current branch
function! ghostgit#core#CurrentBranch(...) abort
  let l:cwd    = get(a:000, 0, '')
  let l:result = ghostgit#core#Run(['rev-parse', '--abbrev-ref', 'HEAD'], l:cwd)
  return empty(l:result) ? '' : l:result[0]
endfunction


function! ghostgit#core#IsRepo(...) abort
  let l:cwd = get(a:000, 0, '')
  let l:output = ghostgit#core#Run(['rev-parse', '--git-dir'], l:cwd)
  return !empty(l:output)
endfunction
