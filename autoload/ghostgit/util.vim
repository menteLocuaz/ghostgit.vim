" ============================================================================
" ghostgit.vim - UI Utilities
" ============================================================================

function! ghostgit#util#OpenBuffer(name, ...) abort
  let l:mods    = get(a:000, 0, 'botright')
  let l:bufname = 'ghostgit://' . a:name

  " Reuse window if already open
  let l:winnr = bufwinnr(l:bufname)
  if l:winnr != -1
    execute l:winnr . 'wincmd w'
    return
  endif

  execute l:mods . ' new'
  silent! execute 'file ' . fnameescape(l:bufname)

  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal nomodifiable
  setlocal nowrap
  setlocal nofoldenable
  setlocal cursorline
  setlocal signcolumn=no
  execute 'setlocal filetype=ghostgit_' . split(a:name, '/')[0]

  " Universal mapping to close the buffer
  nnoremap <silent><buffer> q :bd!<CR>
endfunction


function! ghostgit#util#Render(lines) abort
  setlocal modifiable
  silent! %d _

  if empty(a:lines)
    call setline(1, [''])
  else
    call setline(1, a:lines)
  endif

  setlocal nomodifiable
  normal! gg
endfunction


function! ghostgit#util#Error(msg) abort
  echohl ErrorMsg
  echom '[ghostgit] ' . a:msg
  echohl None
endfunction


function! ghostgit#util#Info(msg) abort
  echohl MoreMsg
  echom '[ghostgit] ' . a:msg
  echohl None
endfunction


function! ghostgit#util#Warn(msg) abort
  echohl WarningMsg
  echom '[ghostgit] ' . a:msg
  echohl None
endfunction
