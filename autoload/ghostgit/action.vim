" ============================================================================
" ghostgit.vim - Actions
" ============================================================================

function! ghostgit#action#OpenFile() abort
  let l:file = s:GetCurrentFile()
  if empty(l:file)
    return
  endif
  execute 'edit! ' . fnameescape(l:file)
endfunction

function! ghostgit#action#VSplitFile() abort
  let l:file = s:GetCurrentFile()
  if empty(l:file)
    return
  endif
  execute 'vsplit! ' . fnameescape(l:file)
endfunction

function! s:GetCurrentFile() abort
  let l:line = getline('.')
  let l:file = matchstr(l:line, '^\s*.\{2}\s\+\zs.*')
  return trim(l:file)
endfunction
