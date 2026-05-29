" ============================================================================
" ghostgit - Status Buffer Keymaps
" ============================================================================

" Basic buffer configuration
setlocal nowrap
setlocal cursorline
setlocal signcolumn=no
setlocal nomodifiable
setlocal buftype=nofile
setlocal bufhidden=wipe
setlocal noswapfile
setlocal foldmethod=manual
setlocal foldcolumn=0

" Display options
setlocal statusline=%!ghostgit#statusline()
setlocal filetype=ghostgit_status

" Keyboard mappings for navigation and actions
" Close buffer
nnoremap <silent><buffer> q :bd!<CR>
nnoremap <silent><buffer> <C-c> :bd!<CR>

" Navigation
nnoremap <silent><buffer> <C-j> j
nnoremap <silent><buffer> <C-k> k
nnoremap <silent><buffer> <Down> j
nnoremap <silent><buffer> <Up> k

" Main actions
nnoremap <silent><buffer> <CR> :call ghostgit#status#Diff()<CR>
nnoremap <silent><buffer> s :call ghostgit#status#Stage()<CR>
nnoremap <silent><buffer> u :call ghostgit#status#Unstage()<CR>
nnoremap <silent><buffer> cc :call ghostgit#status#Commit()<CR>
nnoremap <silent><buffer> ca :call ghostgit#status#Amend()<CR>
nnoremap <silent><buffer> r :call ghostgit#status#Refresh()<CR>

" Additional actions
nnoremap <silent><buffer> ? :call ghostgit#status#ShowHelp()<CR>
nnoremap <silent><buffer> <F1> :call ghostgit#status#ShowHelp()<CR>

" Mappings for file operations
nnoremap <silent><buffer> dd :call ghostgit#status#Delete()<CR>
nnoremap <silent><buffer> i :call ghostgit#status#Ignore()<CR>

" Clear highlighted search
nnoremap <silent><buffer> <C-l> :nohlsearch<CR>

" Mouse navigation settings (if enabled)
if has('mouse')
  setlocal mouse=n
endif

" Function to display contextual help
function! ghostgit#status#ShowHelp() abort
  " Create floating help buffer or display in message
  let l:help_lines = [
        \ 'GhostGit Status Buffer Help:',
        \ '',
        \ 'Key Bindings:',
        \ '  q/<C-c>     - Close buffer',
        \ '  <CR>        - Show diff for file',
        \ '  s           - Stage file',
        \ '  u           - Unstage file',
        \ '  cc          - Commit staged changes',
        \ '  ca          - Amend last commit',
        \ '  r           - Refresh status',
        \ '  dd          - Delete file',
        \ '  i           - Add file to .gitignore',
        \ '  ?/<F1>      - Show this help',
        \ '  <C-l>       - Clear search highlighting',
        \ '  <C-j>/<Down> - Move down',
        \ '  <C-k>/<Up>   - Move up',
        \ ''
        \ ]
  
  " Display help as a message or in a special buffer
  for l:line in l:help_lines
    echo l:line
  endfor
endfunction

" Function for custom status bar
function! ghostgit#statusline() abort
  let l:branch = ghostgit#core#CurrentBranch()
  let l:repo_name = fnamemodify(ghostgit#core#RepoRoot(), ':t')
  return '[GhostGit] ' . l:repo_name . ' (' . l:branch . ')'
endfunction