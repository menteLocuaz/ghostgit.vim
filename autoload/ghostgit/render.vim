" ============================================================================
" ghostgit.vim - Output Renderer
" ============================================================================

" Render repository status
" @param {dict|list} status - Status dictionary from ParseStatusOutput or list of items
function! ghostgit#render#Status(status) abort
  let l:items = type(a:status) == v:t_dict ? a:status.items : a:status
  let l:staged     = []
  let l:unstaged   = []
  let l:untracked  = []
  let l:conflicted = []

  " Classify elements by state
  for l:item in l:items
    let l:class = ghostgit#parser#Classify(l:item)
    if l:class == 'staged'
      call add(l:staged, l:item)
    elseif l:class == 'unstaged'
      call add(l:unstaged, l:item)
    elseif l:class == 'untracked'
      call add(l:untracked, l:item)
    elseif l:class == 'conflicted'
      call add(l:conflicted, l:item)
    endif
  endfor

  " Get repository information
  let l:branch = type(a:status) == v:t_dict ? a:status.branch : ghostgit#core#CurrentBranch()
  let l:repo_root = ghostgit#core#RepoRoot()
  let l:repo_name = fnamemodify(l:repo_root, ':t')
  
  " Build branch status string
  let l:branch_status = empty(l:branch) ? '(no branch)' : l:branch
  if type(a:status) == v:t_dict
    if !empty(a:status.upstream)
      let l:branch_status .= '...[' . a:status.upstream . ']'
    endif
    if a:status.ahead > 0 || a:status.behind > 0
      let l:ab = []
      if a:status.ahead > 0 | call add(l:ab, '+' . a:status.ahead) | endif
      if a:status.behind > 0 | call add(l:ab, '-' . a:status.behind) | endif
      let l:branch_status .= ' (' . join(l:ab, ', ') . ')'
    endif
  endif

  " Build header lines
  let l:lines = [
        \ '  GhostGit — ' . l:branch_status . ' [' . l:repo_name . ']',
        \ '  ' . repeat('─', winwidth(0) > 60 ? 60 : winwidth(0) - 10),
        \ ''
        \ ]

  " Render conflicting files (highest priority)
  if !empty(l:conflicted)
    call add(l:lines, 'Conflicting files:')
    for l:item in l:conflicted
      call add(l:lines, '  ' . l:item.index . l:item.worktree . ' ' . l:item.file)
    endfor
    call add(l:lines, '')
  endif

  " Render changes prepared for commit
  if !empty(l:staged)
    call add(l:lines, 'Changes to be committed:')
    for l:item in l:staged
      " Use more descriptive symbols
      let l:status_symbol = s:GetStatusSymbol(l:item.index)
      call add(l:lines, '  ' . l:status_symbol . ' ' . l:item.file)
    endfor
    call add(l:lines, '')
  endif

  " Render unprepared changes
  if !empty(l:unstaged)
    call add(l:lines, 'Changes not staged for commit:')
    for l:item in l:unstaged
      " Use more descriptive symbols
      let l:status_symbol = s:GetStatusSymbol(l:item.worktree)
      call add(l:lines, '  ' . l:status_symbol . ' ' . l:item.file)
    endfor
    call add(l:lines, '')
  endif

  " Render untracked files
  if !empty(l:untracked)
    call add(l:lines, 'Untracked files:')
    for l:item in l:untracked
      call add(l:lines, '  ?? ' . l:item.file)
    endfor
    call add(l:lines, '')
  endif

  " Show message when no changes
  if empty(l:staged) && empty(l:unstaged) && empty(l:untracked) && empty(l:conflicted)
    call add(l:lines, '  No changes')
    call add(l:lines, '')
  endif

  " Add summary statistics
  let l:stats = []
  if !empty(l:staged)
    call add(l:stats, len(l:staged) . ' staged')
  endif
  if !empty(l:unstaged)
    call add(l:stats, len(l:unstaged) . ' modified')
  endif
  if !empty(l:untracked)
    call add(l:stats, len(l:untracked) . ' untracked')
  endif
  if !empty(l:conflicted)
    call add(l:stats, len(l:conflicted) . ' conflicted')
  endif
  
  if !empty(l:stats)
    call add(l:lines, 'Summary: ' . join(l:stats, ', '))
    call add(l:lines, '')
  endif

  " Add symbol legend if there are elements
  if !empty(l:items)
    call extend(l:lines, [
          \ 'Legend:',
          \ '  M = Modified, A = Added, D = Deleted, R = Renamed, C = Copied',
          \ '  !! = Conflicted, ?? = Untracked',
          \ ''
          \ ])
  endif

  " Add command help
  call extend(l:lines, [
        \ 'Commands: s=stage, u=unstage, <cr>=diff, cc=commit, r=refresh, q=close',
        \ ''
        \ ])

  return l:lines
endfunction

" Get descriptive symbol for file status
function! s:GetStatusSymbol(status_char) abort
  " Convert status characters to more readable symbols
  if a:status_char == 'M'
    return 'M'  " Modified
  elseif a:status_char == 'A'
    return 'A'  " Added
  elseif a:status_char == 'D'
    return 'D'  " Deleted
  elseif a:status_char == 'R'
    return 'R'  " Renamed
  elseif a:status_char == 'C'
    return 'C'  " Copied
  elseif a:status_char == 'U'
    return '!'  " In conflict (unmerged)
  else
    return a:status_char
  endif
endfunction

" Renderer for diff
function! ghostgit#render#Diff(diff_lines) abort
  " In this case, we simply return the lines since diff has its own format
  return a:diff_lines
endfunction

" Commit log renderer
function! ghostgit#render#Log(items) abort
  let l:lines = [
        \ '  GhostGit — Log',
        \ '  ' . repeat('─', 40),
        \ ''
        \ ]

  for l:item in a:items
    let l:line = '  ' . get(l:item, 'graph', '') . get(l:item, 'hash', '???????') . ' ' . get(l:item, 'subject', '')
    call add(l:lines, l:line)
  endfor

  if empty(a:items)
    call add(l:lines, '  (no commits)')
  endif

  call extend(l:lines, [
        \ '',
        \ 'Help: <cr>=view commit, r=refresh, q=close',
        \ ''
        \ ])

  return l:lines
endfunction

" Renderer for branch list
function! ghostgit#render#Branches(branches) abort
  let l:lines = ['Branches:', '']
  
  " Separate local and remote branches
  let l:local_branches = []
  let l:remote_branches = []
  
  for l:branch in a:branches
    if l:branch =~ '^origin/'
      call add(l:remote_branches, l:branch)
    else
      call add(l:local_branches, l:branch)
    endif
  endfor
  
  " Show local branches
  if !empty(l:local_branches)
    call add(l:lines, 'Local branches:')
    for l:branch in l:local_branches
      " Mark current branch
      if l:branch == ghostgit#core#CurrentBranch()
        call add(l:lines, '* ' . l:branch)
      else
        call add(l:lines, '  ' . l:branch)
      endif
    endfor
    call add(l:lines, '')
  endif
  
  " Show remote branches
  if !empty(l:remote_branches)
    call add(l:lines, 'Remote branches:')
    for l:branch in l:remote_branches
      call add(l:lines, '  ' . l:branch)
    endfor
    call add(l:lines, '')
  endif
  
  return l:lines
endfunction

" Renderer for generic command output
function! ghostgit#render#Generic(title, content_lines) abort
  let l:lines = [a:title, repeat('=', len(a:title)), '']
  call extend(l:lines, a:content_lines)
  return l:lines
endfunction
