" ============================================================================
" ghostgit.vim - UI Utilities
" ============================================================================

" Open or reuse a special GhostGit buffer
function! ghostgit#util#OpenBuffer(name, ...) abort
  " Validate arguments
  if empty(a:name)
    call ghostgit#util#Error('Buffer name cannot be empty')
    return
  endif

  " Get window modifiers, use 'botright' as default
  let l:mods = get(a:000, 0, 'botright')
  let l:bufname = 'ghostgit://' . a:name

  " Reuse window if it's already open
  let l:winnr = bufwinnr(l:bufname)
  if l:winnr != -1
    " Switch to existing buffer
    execute l:winnr . 'wincmd w'
    
    " Clear any highlighted searches
    call ghostgit#util#ClearSearchHighlight()
    return
  endif

  " Create a new window with modifiers
  try
    execute l:mods . ' new'
  catch
    " If it cannot be created with the modifiers, create normally
    new
  endtry
  
  " Set buffer name
  silent! execute 'file ' . fnameescape(l:bufname)

  " Configure buffer properties
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal nomodifiable
  setlocal nowrap
  setlocal nofoldenable
  setlocal cursorline
  setlocal signcolumn=no
  
  " Set file type based on buffer name
  let l:filetype_base = split(a:name, '/')[0]
  execute 'setlocal filetype=ghostgit_' . l:filetype_base

  " Universal mappings to close the buffer
  nnoremap <silent><buffer> q :bd!<CR>
  nnoremap <silent><buffer> <C-c> :bd!<CR>
  
  " Mapping to clean highlighted search
  nnoremap <silent><buffer> <C-l> :nohlsearch<CR>
  
  " Save buffer information for future reference
  call ghostgit#state#SetBuffer(a:name, bufname('%'))
  
  " Clear any highlighted searches
  call ghostgit#util#ClearSearchHighlight()
endfunction

" Render content in current buffer
function! ghostgit#util#Render(lines) abort
  " Verify that we are in a valid buffer
  if empty(bufname('%'))
    call ghostgit#util#Error('Cannot render in unnamed buffer')
    return
  endif

  " Make the buffer temporarily modifiable
  setlocal modifiable
  
  " Save current position if possible
  let l:view = winsaveview()
  
  try
    " Clear current buffer contents
    silent! %delete _
    
    " Insert new lines
    if empty(a:lines)
      call setline(1, [''])
    else
      call setline(1, a:lines)
    endif
    
    " Restore position if possible
    if !empty(l:view)
      call winrestview(l:view)
    endif
  finally
    " Always re-create the non-modifiable buffer
    setlocal nomodifiable
  endtry
  
  " Move to start
  normal! gg
endfunction

" Show error message
function! ghostgit#util#Error(msg) abort
  " Validate message
  if empty(a:msg)
    return
  endif
  
  echohl ErrorMsg
  echom '[ghostgit] ' . a:msg
  echohl None
  
  " Record in logs if the logging system is available
  if exists('*ghostgit#log#Error')
    call ghostgit#log#Error(a:msg)
  endif
endfunction

" Show informational message
function! ghostgit#util#Info(msg) abort
  " Validate message
  if empty(a:msg)
    return
  endif
  
  echohl MoreMsg
  echom '[ghostgit] ' . a:msg
  echohl None
  
  " Record in logs if the logging system is available
  if exists('*ghostgit#log#Info')
    call ghostgit#log#Info(a:msg)
  endif
endfunction

" Show warning message
function! ghostgit#util#Warn(msg) abort
  " Validate message
  if empty(a:msg)
    return
  endif
  
  echohl WarningMsg
  echom '[ghostgit] ' . a:msg
  echohl None
  
  " Record in logs if the logging system is available
  if exists('*ghostgit#log#Warn')
    call ghostgit#log#Warn(a:msg)
  endif
endfunction

" Clear search highlights
function! ghostgit#util#ClearSearchHighlight() abort
  if exists('g:ghostgit_clear_search')
    " Only clear if a search has been performed
    if get(g:, 'ghostgit_search_active', 0)
      nohlsearch
      let g:ghostgit_search_active = 0
    endif
  else
    " By default, always clean
    nohlsearch
  endif
endfunction

" Show temporary message (not in message history)
function! ghostgit#util#Echo(msg, ...) abort
  " Validate message
  if empty(a:msg)
    return
  endif
  
  " Get optional highlight group
  let l:hl_group = get(a:000, 0, 'None')
  
  if l:hl_group != 'None'
    execute 'echohl ' . l:hl_group
  endif
  
  echo '[ghostgit] ' . a:msg
  echohl None
endfunction

" Create horizontal split with special buffer
function! ghostgit#util#SplitBuffer(name, ...) abort
  " Get optional size
  let l:size = get(a:000, 0, '')
  
  " create division
  if !empty(l:size)
    execute 'split ' . l:size
  else
    split
  endif
  
  " Open buffer in new window
  call ghostgit#util#OpenBuffer(a:name)
endfunction

" Create vertical split with special buffer
function! ghostgit#util#VSplitBuffer(name, ...) abort
  " Get optional size
  let l:size = get(a:000, 0, '')
  
  " Create vertical division
  if !empty(l:size)
    execute 'vsplit ' . l:size
  else
    vsplit
  endif
  
  " Open buffer in new window
  call ghostgit#util#OpenBuffer(a:name)
endfunction

" Close all GhostGit buffers
function! ghostgit#util#CloseAllBuffers() abort
  " Get buffer list
  let l:buffers = filter(range(1, bufnr('$')), 'buflisted(v:val)')
  
  " Closing GhostGit buffers
  for l:bufnr in l:buffers
    let l:bufname = bufname(l:bufnr)
    if l:bufname =~ '^ghostgit://'
      try
        execute 'bwipeout! ' . l:bufnr
      catch
        " Ignore errors when closing buffers
      endtry
    endif
  endfor
  
  call ghostgit#util#Info('All GhostGit buffers closed')
endfunction