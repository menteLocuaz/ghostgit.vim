" ============================================================================
" ghostgit.vim - Git Output Parser
" ============================================================================

" Parsing a git status line
function! ghostgit#parser#ParseStatusLine(line) abort
  " Validate input
  if empty(a:line)
    return {}
  endif
  
  " Verify if it is a valid status line
  if len(a:line) < 4
    " It could be a line of information like '# branch_name''
    if a:line[0] == '#'
      let l:parts = split(a:line, '\s\+', 1)
      if len(l:parts) >= 2 && l:parts[1] == 'branch'
        return {
              \ 'type': 'branch_info',
              \ 'branch': join(l:parts[2:], ' ')
              \ }
      endif
    endif
    
    " Return raw line if parsing is not possible
    return {
          \ 'type': 'unknown',
          \ 'raw': a:line
          \ }
  endif
  
  " Extract components from the status line
  let l:index    = a:line[0]
  let l:worktree = a:line[1]
  let l:file     = a:line[3:]
  
  " Handling renamed/copied files (format: XY file_name -> new_file_name)
  if l:index =~ '[RC]' || l:worktree =~ '[RC]'
    " Separate original and new names
    let l:parts = split(l:file, ' -> ')
    if len(l:parts) == 2
      return {
            \ 'index': l:index,
            \ 'worktree': l:worktree,
            \ 'file': l:parts[1],
            \ 'original_file': l:parts[0],
            \ 'type': 'file_change'
            \ }
    endif
  endif
  
  " Return standard structure
  return {
        \ 'index': l:index,
        \ 'worktree': l:worktree,
        \ 'file': l:file,
        \ 'type': 'file_change'
        \ }
endfunction

" Classify the state of an item
function! ghostgit#parser#Classify(item) abort
  " Validate input
  if empty(a:item)
    return 'unknown'
  endif
  
  " Handling different types of items
  if get(a:item, 'type', '') == 'branch_info'
    return 'branch_info'
  endif
  
  if get(a:item, 'type', '') == 'unknown'
    return 'unknown'
  endif
  
  " Git-based classification
  " Untracked files
  if a:item.index == '?' && a:item.worktree == '?'
    return 'untracked'
  endif
  
  " Conflicting files (unmerged)
  if a:item.index == 'U' || a:item.worktree == 'U' || 
    \ (a:item.index == 'A' && a:item.worktree == 'A') ||
    \ (a:item.index == 'D' && a:item.worktree == 'D')
    return 'conflicted'
  endif
  
  " Files prepared for commit (staged)
  if a:item.index != ' ' && a:item.index != '?'
    return 'staged'
  endif
  
  " Modified but unstaged files
  if a:item.worktree != ' ' && a:item.worktree != '?'
    return 'unstaged'
  endif
  
  " Unmodified files
  return 'unmodified'
endfunction

" Parse full output of git status
function! ghostgit#parser#ParseStatusOutput(lines) abort
  " Validate input
  if empty(a:lines)
    return {'branch': '', 'items': []}
  endif
  
  let l:branch = ''
  let l:items = []
  
  " Process each line
  for l:line in a:lines
    " Skip empty lines
    if empty(l:line)
      continue
    endif
    
    " Parse line
    let l:item = ghostgit#parser#ParseStatusLine(l:line)
    
    " Extract branch information if present
    if get(l:item, 'type', '') == 'branch_info'
      let l:branch = l:item.branch
    elseif !empty(l:item)
      " Add archive items
      call add(l:items, l:item)
    endif
  endfor
  
  return {
        \ 'branch': l:branch,
        \ 'items': l:items
        \ }
endfunction

" Obtain a legible description of the condition
function! ghostgit#parser#GetStatusDescription(item) abort
  " Validate input
  if empty(a:item)
    return 'Unknown'
  endif
  
  " Get ranking
  let l:class = ghostgit#parser#Classify(a:item)
  
  " Generate state-based description
  if l:class == 'untracked'
    return 'Untracked file'
  elseif l:class == 'staged'
    return s:GetStatusCodeDescription(a:item.index) . ' (staged)'
  elseif l:class == 'unstaged'
    return s:GetStatusCodeDescription(a:item.worktree) . ' (not staged)'
  elseif l:class == 'conflicted'
    return 'Unresolved conflict'
  elseif l:class == 'unmodified'
    return 'Unmodified'
  else
    return 'Unknown status'
  endif
endfunction

" Get status code description
function! s:GetStatusCodeDescription(code) abort
  let l:descriptions = {
        \ 'M': 'Modified',
        \ 'A': 'Added',
        \ 'D': 'Deleted',
        \ 'R': 'Renamed',
        \ 'C': 'Copied',
        \ 'U': 'Unmerged',
        \ '?': 'Untracked'
        \ }
  
  return get(l:descriptions, a:code, 'Unknown (' . a:code . ')')
endfunction

" Parse branch information
function! ghostgit#parser#ParseBranchInfo(line) abort
  " Validate input
  if empty(a:line) || a:line[0] != '#'
    return {}
  endif
  
  " Extract branch information
  if a:line =~ '^# branch\.head '
    let l:branch = substitute(a:line, '^# branch\.head ', '', '')
    return {'type': 'current_branch', 'branch': l:branch}
  elseif a:line =~ '^# branch\.upstream '
    let l:upstream = substitute(a:line, '^# branch\.upstream ', '', '')
    return {'type': 'upstream_branch', 'upstream': l:upstream}
  elseif a:line =~ '^# branch\.ab '
    " Extract ahead/behind info
    let l:ab_info = substitute(a:line, '^# branch\.ab ', '', '')
    let l:parts = split(l:ab_info, ' ')
    let l:ahead = 0
    let l:behind = 0
    
    for l:part in l:parts
      if l:part =~ '^\\+'
        let l:ahead = str2nr(substitute(l:part, '^\\+', '', ''))
      elseif l:part =~ '^-'
        let l:behind = str2nr(substitute(l:part, '^-', '', ''))
      endif
    endfor
    
    return {'type': 'branch_ab', 'ahead': l:ahead, 'behind': l:behind}
  endif
  
  return {'type': 'unknown', 'raw': a:line}
endfunction