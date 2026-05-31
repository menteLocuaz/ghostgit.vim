" ============================================================================
" ghostgit.vim - Git Blame
" ============================================================================

" Open blame window for the current file
function! ghostgit#blame#Open() abort
  let l:file = expand('%')
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
  
  " Create blame buffer immediately with a loading message
  call ghostgit#util#OpenBuffer(l:bufname)
  let l:bufnr = bufnr('%')
  call ghostgit#util#Render(['  Loading blame for ' . l:file . '...'])
  
  " Schedule async job
  call ghostgit#job#Schedule('blame:' . l:file, ['git', 'blame', '--', l:file], {
        \ 'bufnr': l:bufnr,
        \ 'cwd': l:repo_root,
        \ 'on_success': {lines -> ghostgit#util#RenderToBuffer(l:bufnr, lines)},
        \ 'on_failure': {err -> ghostgit#util#Error('Failed to get blame for ' . l:file)}
        \ })
endfunction
