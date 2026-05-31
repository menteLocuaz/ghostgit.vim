" ============================================================================
" ghostgit - Diff Buffer Keymaps
" ============================================================================

setlocal nowrap
setlocal cursorline
setlocal nomodifiable
setlocal readonly
setlocal foldmethod=syntax
setlocal foldlevel=99

nnoremap <silent><buffer> q :bd!<CR>
nnoremap <silent><buffer> r :call ghostgit#diff#Refresh()<CR>
nnoremap <silent><buffer> <C-c> :bd!<CR>
