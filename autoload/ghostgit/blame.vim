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

  let l:output = ghostgit#core#Run(['blame', '--', l:file])
  if empty(l:output)
    return
  endif

  " Create blame buffer
  call ghostgit#util#OpenBuffer('blame/' . l:file)
  
  " Render content
  call ghostgit#util#Render(l:output)
  
  " Buffer configuration
  setlocal filetype=ghostgit_blame
  setlocal nomodifiable
  
  " Keymaps
  nnoremap <silent><buffer> q :bd!<CR>
endfunction
