" ============================================================================
" ghostgit.vim - Git Output Parser
" ============================================================================

" Parse a line from `git status --short`
function! ghostgit#parser#ParseStatusLine(line) abort
  if empty(a:line) || len(a:line) < 3
    return {}
  endif

  " Lines starting with # are branch/detail info, not file changes
  if a:line[0] == '#'
    return {'type': 'unknown', 'raw': a:line}
  endif

  " Validate that characters at position 0 and 1 are valid status indicators
  if a:line[0] !~# '[ MADRCU?!]' || a:line[1] !~# '[ MADRCU?!]'
    return {'type': 'unknown', 'raw': a:line}
  endif

  let l:index    = a:line[0]
  let l:worktree = a:line[1]
  let l:file     = a:line[3:]
  let l:result = {
        \ 'index': l:index,
        \ 'worktree': l:worktree,
        \ 'file': l:file,
        \ 'type': 'file_change',
        \ 'raw': a:line
        \ }

  " Handle renamed/copied files (R or C with ->)
  if l:index == 'R' || l:index == 'C' || l:worktree == 'R' || l:worktree == 'C'
    let l:parts = split(l:file, ' -> ')
    if len(l:parts) == 2
      let l:result.file = l:parts[1]
      let l:result.original_file = l:parts[0]
    endif
  endif

  return l:result
endfunction

" Classify a status item
function! ghostgit#parser#Classify(item) abort
  if empty(a:item)
    return 'unknown'
  endif
  if has_key(a:item, 'type') && a:item.type != 'file_change'
    return a:item.type
  endif
  if !has_key(a:item, 'index')
    return 'unknown'
  endif
  " Conflicted: both sides modified
  if a:item.index == 'U' || a:item.worktree == 'U'
    return 'conflicted'
  endif
  if (a:item.index == 'A' && a:item.worktree == 'A') ||
        \ (a:item.index == 'D' && a:item.worktree == 'D')
    return 'conflicted'
  endif
  if a:item.index == '?' | return 'untracked' | endif
  if a:item.index != ' ' | return 'staged'    | endif
  if a:item.worktree != ' ' | return 'unstaged' | endif
  return 'unmodified'
endfunction

" Parse a line from `git log --oneline --graph`
function! ghostgit#parser#ParseLogLine(line) abort
  if empty(a:line)
    return {}
  endif

  " Handle graph characters at the beginning
  let l:hash_match = matchlist(a:line, '^\([*|\\\/ ]*\)\(\x\{7,\}\)\s\+\(.*\)$')
  
  if !empty(l:hash_match)
    return {
          \ 'graph': l:hash_match[1],
          \ 'hash': l:hash_match[2],
          \ 'subject': l:hash_match[3]
          \ }
  endif

  " Check for continuation/pure-graph lines like |/
  if a:line =~# '^[*|\\/ ]\+$'
    return {}
  endif

  " Fallback for non-graph lines or simple format
  let l:parts = split(a:line, '\s\+', 2)
  if len(l:parts) < 2 && empty(l:parts[0])
    return {}
  endif
  return {
        \ 'graph': '',
        \ 'hash': get(l:parts, 0, ''),
        \ 'subject': get(l:parts, 1, '')
        \ }
endfunction

" Parse full `git status --short --branch` output
function! ghostgit#parser#ParseStatusOutput(lines) abort
  let l:result = {
        \ 'branch': '',
        \ 'upstream': '',
        \ 'ahead': 0,
        \ 'behind': 0,
        \ 'items': []
        \ }

  if empty(a:lines)
    return l:result
  endif

  for l:line in a:lines
    if l:line =~# '^## '
      " Parse branch line: ## master...origin/master [ahead 1, behind 2]
      let l:branch_info = substitute(l:line, '^## ', '', '')
      
      " Extract ahead/behind
      let l:ab_match = matchlist(l:branch_info, '\[ahead \(\d\+\)\%(, behind \(\d\+\)\)\?\]')
      if !empty(l:ab_match)
        let l:result.ahead = str2nr(l:ab_match[1])
        let l:result.behind = str2nr(get(l:ab_match, 2, '0'))
      else
        let l:behind_only = matchlist(l:branch_info, '\[behind \(\d\+\)\]')
        if !empty(l:behind_only)
          let l:result.behind = str2nr(l:behind_only[1])
        endif
      endif

      " Extract branch and upstream
      let l:names = split(substitute(l:branch_info, '\s\+\[.*\]$', '', ''), '\.\.\.')
      let l:result.branch = get(l:names, 0, '')
      let l:result.upstream = get(l:names, 1, '')
      
    elseif l:line =~# '^#'
      let l:branch_info = ghostgit#parser#ParseBranchInfo(l:line)
      if !empty(l:branch_info)
        if l:branch_info.type ==# 'current_branch'
          let l:result.branch = l:branch_info.branch
        elseif l:branch_info.type ==# 'upstream_branch'
          let l:result.upstream = l:branch_info.upstream
        elseif l:branch_info.type ==# 'branch_ab'
          let l:result.ahead = l:branch_info.ahead
          let l:result.behind = l:branch_info.behind
        endif
      endif
      continue
    elseif !empty(l:line)
      let l:item = ghostgit#parser#ParseStatusLine(l:line)
      if !empty(l:item) && l:item.type ==# 'file_change'
        call add(l:result.items, l:item)
      endif
    endif
  endfor

  return l:result
endfunction

" Get a human-readable description of a status item
function! ghostgit#parser#GetStatusDescription(item) abort
  if empty(a:item)
    return 'Unknown'
  endif

  let l:class = ghostgit#parser#Classify(a:item)

  if l:class == 'staged'
    if a:item.index == 'M'
      return 'Modified (staged)'
    elseif a:item.index == 'A'
      return 'Added (staged)'
    elseif a:item.index == 'D'
      return 'Deleted (staged)'
    elseif a:item.index == 'R'
      return 'Renamed (staged)'
    elseif a:item.index == 'C'
      return 'Copied (staged)'
    endif
  elseif l:class == 'unstaged'
    if a:item.worktree == 'M'
      return 'Modified (not staged)'
    elseif a:item.worktree == 'D'
      return 'Deleted (not staged)'
    endif
  elseif l:class == 'untracked'
    return 'Untracked file'
  elseif l:class == 'conflicted'
    return 'Unresolved conflict'
  elseif l:class == 'unmodified'
    return 'Unmodified'
  endif

  return 'Unknown'
endfunction

" Parse branch info line (# branch.*)
function! ghostgit#parser#ParseBranchInfo(line) abort
  if empty(a:line)
    return {}
  endif

  " # branch.head <name>
  let l:head_match = matchlist(a:line, '^# branch\.head\s\+\(.*\)$')
  if !empty(l:head_match)
    return {'type': 'current_branch', 'branch': l:head_match[1]}
  endif

  " # branch.upstream <name>
  let l:upstream_match = matchlist(a:line, '^# branch\.upstream\s\+\(.*\)$')
  if !empty(l:upstream_match)
    return {'type': 'upstream_branch', 'upstream': l:upstream_match[1]}
  endif

  " # branch.ab +<ahead> -<behind>
  let l:ab_match = matchlist(a:line, '^# branch\.ab\s\++\(\d\+\)\s\+-\(\d\+\)$')
  if !empty(l:ab_match)
    return {'type': 'branch_ab', 'ahead': str2nr(l:ab_match[1]), 'behind': str2nr(l:ab_match[2])}
  endif

  return {}
endfunction
