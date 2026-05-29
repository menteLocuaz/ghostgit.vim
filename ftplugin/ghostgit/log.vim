" ============================================================================
" ghostgit - Log Buffer Keymaps
" ============================================================================

setlocal nowrap
setlocal cursorline
setlocal signcolumn=no
setlocal nomodifiable
setlocal buftype=nofile
setlocal bufhidden=wipe

nnoremap <silent><buffer> <cr> :call ghostgit#log#OpenCommit()<CR>
nnoremap <silent><buffer> r    :call ghostgit#log#Refresh()<CR>
nnoremap <silent><buffer> q    :bd!<CR>
