" ============================================================================
" ghostgit - Status Buffer Keymaps
" ============================================================================

setlocal nowrap
setlocal cursorline
setlocal signcolumn=no
setlocal nomodifiable
setlocal buftype=nofile
setlocal bufhidden=wipe
setlocal noswapfile

" Keyboard mappings using the dispatcher
nnoremap <silent><buffer> <cr> :call ghostgit#action#Dispatch('diff')<CR>
nnoremap <silent><buffer> o    :call ghostgit#action#Dispatch('open')<CR>
nnoremap <silent><buffer> v    :call ghostgit#action#Dispatch('vsplit')<CR>
nnoremap <silent><buffer> s    :call ghostgit#action#Dispatch('stage')<CR>
nnoremap <silent><buffer> u    :call ghostgit#action#Dispatch('unstage')<CR>
nnoremap <silent><buffer> cc   :call ghostgit#status#Commit()<CR>
nnoremap <silent><buffer> r    :call ghostgit#status#Refresh()<CR>
nnoremap <silent><buffer> q    :bd!<CR>

" Automatic reload on enter
augroup ghostgit_status
  autocmd! * <buffer>
  autocmd BufEnter <buffer> call ghostgit#status#Refresh()
augroup END
