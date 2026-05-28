" ============================================================================
" ghostgit.vim - Test Runner (vader.vim)
" ============================================================================
"
" Prerequisites:
"   - Install vader.vim (https://github.com/junegunn/vader.vim)
"     e.g. via vim-plug: Plug 'junegunn/vader.vim'
"
" Usage (run from project root):
"   PROJ=$(pwd)
"   vim -c "set rtp^=\$PROJ" -c 'Vader! test/specs/*.vader' -c 'q!'
"
"   With neovim headless:
"   PROJ=$(pwd)
"   nvim --headless -c "set rtp^=\$PROJ" -c 'Vader! test/specs/*.vader' -c 'qall!'
