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

" Keyboard mappings for status actions
nnoremap <silent><buffer> <cr> :call ghostgit#status#Diff()<CR>
nnoremap <silent><buffer> s    :call ghostgit#status#Stage()<CR>
nnoremap <silent><buffer> u    :call ghostgit#status#Unstage()<CR>
nnoremap <silent><buffer> cc   :call ghostgit#status#Commit()<CR>
nnoremap <silent><buffer> r    :call ghostgit#status#Refresh()<CR>
nnoremap <silent><buffer> q    :bd!<CR>
