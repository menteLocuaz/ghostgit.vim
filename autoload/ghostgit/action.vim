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

  let l:raw_line = getline('.')

  " Skip header/separator/help lines
  if empty(l:raw_line) || l:raw_line =~# '^\s*[#─]' || l:raw_line =~# '^\s*$'
    return {}
  endif

  " Look up in cache by matching file name in the rendered line.
  " Sort by file length descending to avoid substring collisions
  " (e.g. "staged.txt" matching inside "unstaged.txt").
  let l:sorted = sort(copy(l:items), {a, b -> len(b.file) - len(a.file)})
  for l:item in l:sorted
    if has_key(l:item, 'file') && stridx(l:raw_line, l:item.file) >= 0
      return l:item
    endif
  endfor

  return {}
endfunction
