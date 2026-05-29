" ============================================================================
" ghostgit.vim - Actions
" ============================================================================

" Open the file under cursor in the current window
function! ghostgit#action#OpenFile() abort
  " Get the file path from the current line
  let l:file = s:GetCurrentFile()
  
  " Validate file path
  if empty(l:file)
    echohl WarningMsg
    echom 'ghostgit: No file found on current line'
    echohl None
    return
  endif
  
  " Check if file exists
  if !filereadable(l:file)
    echohl WarningMsg
    echom 'ghostgit: File not found: ' . l:file
    echohl None
    return
  endif
  
  " Open the file
  try
    execute 'edit! ' . fnameescape(l:file)
  catch
    echohl ErrorMsg
    echom 'ghostgit: Failed to open file: ' . l:file . ' (' . v:exception . ')'
    echohl None
  endtry
endfunction

" Open the file under cursor in a vertical split
function! ghostgit#action#VSplitFile() abort
  " Get the file path from the current line
  let l:file = s:GetCurrentFile()
  
  " Validate file path
  if empty(l:file)
    echohl WarningMsg
    echom 'ghostgit: No file found on current line'
    echohl None
    return
  endif
  
  " Check if file exists
  if !filereadable(l:file)
    echohl WarningMsg
    echom 'ghostgit: File not found: ' . l:file
    echohl None
    return
  endif
  
  " Open the file in a vertical split
  try
    execute 'vsplit! ' . fnameescape(l:file)
  catch
    echohl ErrorMsg
    echom 'ghostgit: Failed to open file in vertical split: ' . l:file . ' (' . v:exception . ')'
    echohl None
  endtry
endfunction

" Extract file path from the current line
" @return {string} File path or empty string if not found
function! s:GetCurrentFile() abort
  " Get the current line
  let l:line = getline('.')
  
  " Validate line content
  if empty(l:line)
    return ''
  endif
  
  " Extract file path using pattern matching
  " Pattern explanation:
  " ^\s*     - Match beginning of line with optional whitespace
  " .\{2}    - Match exactly 2 characters (status indicators)
  " \s\+     - Match one or more whitespace characters
  " \zs      - Start match here (exclude previous pattern from result)
  " .*       - Match rest of line (file path)
  let l:file = matchstr(l:line, '^\s*.\{2}\s\+\zs.*')
  
  " Trim whitespace and return
  return trim(l:file)
endfunction
