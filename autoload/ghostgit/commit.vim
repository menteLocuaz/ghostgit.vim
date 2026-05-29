" ============================================================================
" ghostgit.vim - Commit Interface
" ============================================================================

" Open the commit message buffer
function! ghostgit#commit#Open(...) abort
  let l:opts = get(a:000, 0, '')
  
  " Create a temporary file for the commit message
  let l:commit_editmsg = ghostgit#core#RepoRoot() . '/.git/COMMIT_EDITMSG'
  
  " Open the file in a new split
  execute 'botright split ' . fnameescape(l:commit_editmsg)
  
  " Set buffer options
  setlocal buftype=
  setlocal bufhidden=wipe
  setlocal filetype=gitcommit
  
  " Save options for when the buffer is closed
  let b:ghostgit_commit_opts = l:opts
  
  " Define mapping to finish commit
  nnoremap <silent><buffer> <C-c><C-c> :call ghostgit#commit#Finish()<CR>
  nnoremap <silent><buffer> q :bd!<CR>
  
  call ghostgit#util#Info('Enter commit message and press <C-c><C-c> to finish')
endfunction

" Finish the commit process
function! ghostgit#commit#Finish() abort
  " Save the current buffer
  silent! write
  
  let l:opts = get(b:, 'ghostgit_commit_opts', '')
  let l:msg_file = expand('%:p')
  
  " Close the commit buffer
  bd!
  
  " Run git commit
  let l:args = ['commit', '-F', l:msg_file]
  if !empty(l:opts)
    call add(l:args, l:opts)
  endif
  
  let l:output = ghostgit#core#Run(l:args)
  
  if !empty(l:output)
    call ghostgit#util#Info('Commit successful')
    " Refresh status if open
    let l:status_buf = bufnr('ghostgit://status')
    if l:status_buf != -1
      call ghostgit#status#Refresh()
    endif
  endif
endfunction
