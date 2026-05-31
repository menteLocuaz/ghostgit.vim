" ============================================================================
" ghostgit.vim - UI Utilities
" ============================================================================

" Open or reuse a special GhostGit buffer
function! ghostgit#util#OpenBuffer(name, ...) abort
  " Get window modifiers, use 'botright' as default
  let l:mods = get(a:000, 0, 'botright')
  let l:bufname = 'ghostgit://' . a:name

  " Reuse window if it's already open
  let l:winnr = bufwinnr(l:bufname)
  if l:winnr != -1
    execute l:winnr . 'wincmd w'
    return
  endif

  " Reuse existing buffer if it exists (even if not in a window)
  let l:existing = bufnr(l:bufname)
  if l:existing != -1
    execute 'buffer ' . l:existing
    return
  endif

  " Create a new window
  execute l:mods . ' new'
  
  " Set buffer name
  silent! execute 'file ' . fnameescape(l:bufname)

  " Configure buffer properties
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal nomodifiable
  setlocal readonly
  setlocal nowrap
  setlocal nofoldenable
  setlocal cursorline
  setlocal signcolumn=no
  
  " Set base file type for GhostGit buffers (use only first segment to keep it valid)
  let l:ft = substitute(split(a:name, '/')[0], '[^[:alnum:]_.]', '_', 'g')
  execute 'setlocal filetype=ghostgit_' . l:ft

  " Universal mappings to close the buffer
  nnoremap <silent><buffer> q :bd!<CR>
endfunction

" Render content in current buffer
function! ghostgit#util#Render(lines) abort
  call ghostgit#util#RenderToBuffer(bufnr('%'), a:lines)
  normal! gg
endfunction

" Render content in a specific buffer by number (non-disruptive)
function! ghostgit#util#RenderToBuffer(bufnr, lines) abort
  if !bufexists(a:bufnr) | return | endif

  " Ensure lines is a list
  let l:lines = type(a:lines) == v:t_list ? a:lines : []

  " Neovim-specific optimization
  if has('nvim-0.5')
    let l:is_modifiable = nvim_buf_get_option(a:bufnr, 'modifiable')
    call nvim_buf_set_option(a:bufnr, 'modifiable', v:true)
    call nvim_buf_set_lines(a:bufnr, 0, -1, v:false, l:lines)
    silent! call nvim_buf_set_option(a:bufnr, 'modifiable', l:is_modifiable)
    return
  endif

  " Vim 8 / Fallback
  let l:is_modifiable = getbufvar(a:bufnr, '&modifiable')
  let l:is_readonly = getbufvar(a:bufnr, '&readonly')

  silent! call setbufvar(a:bufnr, '&modifiable', 1)
  silent! call setbufvar(a:bufnr, '&readonly', 0)

  silent! call deletebufline(a:bufnr, 1, '$')
  if empty(a:lines)
    call setbufline(a:bufnr, 1, [''])
  else
    call setbufline(a:bufnr, 1, a:lines)
  endif

  silent! call setbufvar(a:bufnr, '&modifiable', l:is_modifiable)
  silent! call setbufvar(a:bufnr, '&readonly', l:is_readonly)
endfunction

" Show error message
function! ghostgit#util#Error(msg) abort
  echohl ErrorMsg
  echom '[ghostgit] ' . a:msg
  echohl None
endfunction

" Show informational message
function! ghostgit#util#Info(msg) abort
  echohl MoreMsg
  echom '[ghostgit] ' . a:msg
  echohl None
endfunction

" Show warning message
function! ghostgit#util#Warn(msg) abort
  echohl WarningMsg
  echom '[ghostgit] ' . a:msg
  echohl None
endfunction

" Get the full buffer name for a given name
function! ghostgit#util#GetBufferName(name) abort
  if empty(a:name)
    return 'ghostgit://'
  endif
  return 'ghostgit://' . a:name
endfunction

" Find a GhostGit buffer by name, return bufnr or -1
function! ghostgit#util#FindBuffer(name) abort
  return bufnr('ghostgit://' . a:name)
endfunction

" Close the current GhostGit buffer
function! ghostgit#util#CloseBuffer() abort
  let l:bufnr = bufnr('%')
  if l:bufnr != -1
    silent! execute 'bwipeout! ' . l:bufnr
  endif
endfunction

" Escape special characters in a file path for shell use
function! ghostgit#util#EscapePath(path) abort
  if empty(a:path)
    return ''
  endif
  return escape(a:path, ' \!@#$%^&*()[]{}|;''"`~')
endfunction
