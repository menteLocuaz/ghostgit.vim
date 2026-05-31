" ============================================================================
" ghostgit - Commit Buffer Keymaps
" ============================================================================

setlocal nospell
setlocal signcolumn=yes

nnoremap <silent><buffer> <C-c><C-c> :call ghostgit#commit#Finish()<CR>
inoremap <silent><buffer> <C-c><C-c> <Esc>:call ghostgit#commit#Finish()<CR>
nnoremap <silent><buffer> q :bd!<CR>
