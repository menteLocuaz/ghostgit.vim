" ============================================================================
" ghostgit.vim - Action Dispatcher
" ============================================================================

" Dispatch an action based on the current context
function! ghostgit#action#Dispatch(action_name, ...) abort
  let l:ctx = s:GetContext()
  let l:target = get(a:000, 0, '')

  if l:ctx ==# 'status'
    return s:DispatchStatus(a:action_name, l:target)
  elseif l:ctx ==# 'log'
    return s:DispatchLog(a:action_name, l:target)
  endif

  call ghostgit#util#Error('No action handler for context: ' . l:ctx)
endfunction

" Get current buffer context based on filetype
function! s:GetContext() abort
  let l:ft = &filetype
  if l:ft =~# '^ghostgit_'
    return substitute(l:ft, '^ghostgit_', '', '')
  endif
  return 'unknown'
endfunction

" Handle actions in status buffer
function! s:DispatchStatus(action, target) abort
  if a:action ==# 'open'
    return ghostgit#action#OpenFile()
  elseif a:action ==# 'vsplit'
    return ghostgit#action#VSplitFile()
  elseif a:action ==# 'diff'
    return ghostgit#status#Diff()
  elseif a:action ==# 'stage'
    return ghostgit#status#Stage()
  elseif a:action ==# 'unstage'
    return ghostgit#status#Unstage()
  elseif a:action ==# 'toggle'
    return s:ToggleStage()
  endif
endfunction

" Toggle stage/unstage for item at cursor
function! s:ToggleStage() abort
  let l:item = s:GetItemAtCursor()
  if empty(l:item) | return | endif

  let l:class = ghostgit#parser#Classify(l:item)
  if l:class ==# 'staged'
    call ghostgit#status#Unstage()
  else
    call ghostgit#status#Stage()
  endif
endfunction

" Handle actions in log buffer
function! s:DispatchLog(action, target) abort
  " To be implemented
  call ghostgit#util#Info('Action ' . a:action . ' not yet implemented for log')
endfunction

" Open the file under cursor in the current window
function! ghostgit#action#OpenFile() abort
  let l:item = s:GetItemAtCursor()
  if empty(l:item) || !has_key(l:item, 'file') | return | endif
  
  let l:file = l:item.file
  if !filereadable(l:file)
    call ghostgit#util#Warn('File not found: ' . l:file)
    return
  endif
  
  call s:JumpToEditorWindow()
  execute 'edit ' . fnameescape(l:file)
endfunction

" Open the file under cursor in a vertical split
function! ghostgit#action#VSplitFile() abort
  let l:item = s:GetItemAtCursor()
  if empty(l:item) || !has_key(l:item, 'file') | return | endif
  
  let l:file = l:item.file
  if !filereadable(l:file)
    call ghostgit#util#Warn('File not found: ' . l:file)
    return
  endif
  
  call s:JumpToEditorWindow()
  execute 'vsplit ' . fnameescape(l:file)
endfunction

" Find a suitable window to open a file (avoiding GhostGit buffers)
function! s:JumpToEditorWindow() abort
  " Try to find a window that isn't a GhostGit buffer
  for l:winnr in range(1, winnr('$'))
    let l:bufnr = winbufnr(l:winnr)
    if bufname(l:bufnr) !~# '^ghostgit://'
      execute l:winnr . 'wincmd w'
      return
    endif
  endfor
  
  " If all windows are GhostGit, open in a new split above
  leftabove split
endfunction

" Retrieve the state item associated with the current cursor line
function! s:GetItemAtCursor() abort
  let l:ctx = s:GetContext()
  if l:ctx ==# 'unknown' | return {} | endif

  " Items are cached in state during rendering
  let l:items = ghostgit#state#GetCachedItems(l:ctx)
  if empty(l:items) | return {} | endif

  " The line number in the buffer corresponds to the index in l:items
  " (Adjusted for header lines)
  let l:line = line('.')
  
  " In status buffer, items start after the header (usually line 5 or 6)
  " It's better to search the items list for a matching file name if possible,
  " but since we rendered them in order, we can calculate the index.
  " HOWEVER, for robustness, we'll use the parser to get the file name 
  " then look it up in the cache.
  
  let l:raw_line = getline('.')
  let l:parsed = ghostgit#parser#ParseStatusLine(l:raw_line)
  if empty(l:parsed) || !has_key(l:parsed, 'file') | return {} | endif

  " Look up in cache to get full item metadata
  for l:item in l:items
    if has_key(l:item, 'file') && l:item.file ==# l:parsed.file
      return l:item
    endif
  endfor

  return l:parsed
endfunction
