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
  
  " Set base file type for GhostGit buffers
  setlocal filetype=ghostgit

  " Universal mappings to close the buffer
  nnoremap <silent><buffer> q :bd!<CR>
endfunction

" Render content in current buffer
function! ghostgit#util#Render(lines) abort
  " Make the buffer temporarily modifiable and not readonly
  setlocal modifiable noreadonly
  
  " Clear current buffer contents
  silent! %delete _
  
  " Insert new lines
  if empty(a:lines)
    call setline(1, [''])
  else
    call setline(1, a:lines)
  endif
  
  " Make non-modifiable and readonly again
  setlocal nomodifiable readonly
  normal! gg
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
