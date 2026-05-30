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
  endif
endfunction

" Handle actions in log buffer
function! s:DispatchLog(action, target) abort
  " To be implemented
  call ghostgit#util#Info('Action ' . a:action . ' not yet implemented for log')
endfunction

" Open the file under cursor in the current window
function! ghostgit#action#OpenFile() abort
  let l:file = s:GetCurrentFile()
  if empty(l:file) | return | endif
  
  if !filereadable(l:file)
    call ghostgit#util#Warn('File not found: ' . l:file)
    return
  endif
  
  execute 'edit ' . fnameescape(l:file)
endfunction

" Open the file under cursor in a vertical split
function! ghostgit#action#VSplitFile() abort
  let l:file = s:GetCurrentFile()
  if empty(l:file) | return | endif
  
  if !filereadable(l:file)
    call ghostgit#util#Warn('File not found: ' . l:file)
    return
  endif
  
  execute 'vsplit ' . fnameescape(l:file)
endfunction

" Extract file path from the current line (status buffer specific)
function! s:GetCurrentFile() abort
  let l:line = getline('.')
  
  " Match files in status buffer: '  M filename'
  let l:file = matchstr(l:line, '^  .. \zs.*')
  
  if empty(l:file)
    " Try untracked: '  ?? filename'
    let l:file = matchstr(l:line, '^  ?? \zs.*')
  endif

  return trim(l:file)
endfunction
