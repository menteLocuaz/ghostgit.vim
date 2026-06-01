" ============================================================================
" ghostgit.vim - Git Blame
" ============================================================================

" Open blame window for the current file
" @param {string} [filename] - Optional filename to blame. Defaults to current file.
function! ghostgit#blame#Open(...) abort
  let l:file = get(a:000, 0, expand('%'))
  let l:is_side_by_side = a:0 == 0 " Default to vertical split if no filename arg
  
  if empty(l:file)
    call ghostgit#util#Error('No file in current buffer')
    return
  endif

  if !ghostgit#core#IsRepo()
    call ghostgit#util#Error('Not in a git repository')
    return
  endif

  let l:repo_root = ghostgit#core#RepoRoot()
  let l:bufname = 'blame/' . l:file
  let l:original_win = win_getid()
  
  " Create blame buffer
  if l:is_side_by_side
    " Open vertical split on the left
    let l:mods = 'vertical leftabove'
    call ghostgit#util#OpenBuffer(l:bufname, {'mods': l:mods, 'filetype': 'ghostgit_blame'})
    vertical resize 40
    setlocal winfixwidth
    setlocal scrollbind
  else
    call ghostgit#util#OpenBuffer(l:bufname)
  endif

  let l:bufnr = bufnr('%')
  let l:winid = win_getid()
  call ghostgit#util#Render(['  Loading...'])
  
  " Enable scrollbind in the original window if side-by-side
  if l:is_side_by_side
    let l:blame_win = l:winid
    call win_gotoid(l:original_win)
    setlocal scrollbind
    call win_gotoid(l:blame_win)
  endif

  " Schedule async job
  call ghostgit#job#Schedule('blame:' . l:file, ['git', 'blame', '--', l:file], {
        \ 'bufnr': l:bufnr,
        \ 'cwd': l:repo_root,
        \ 'on_success': {lines -> s:OnBlameResult(l:bufnr, lines, l:is_side_by_side)},
        \ 'on_failure': {err -> ghostgit#util#Error('Failed to get blame for ' . l:file)}
        \ })
endfunction

" Callback for blame result
function! s:OnBlameResult(bufnr, lines, is_side_by_side) abort
  call ghostgit#util#RenderToBuffer(a:bufnr, a:lines)
  if a:is_side_by_side
    " Sync scroll after rendering
    syncbind
  endif
endfunction
