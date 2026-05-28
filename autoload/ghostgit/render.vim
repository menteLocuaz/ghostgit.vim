" ============================================================================
" ghostgit.vim - Output Renderer
" ============================================================================

function! ghostgit#render#Status(items) abort
  let l:staged     = []
  let l:unstaged   = []
  let l:untracked  = []

  for l:item in a:items
    let l:class = ghostgit#parser#Classify(l:item)
    if l:class == 'staged'
      call add(l:staged, l:item)
    elseif l:class == 'unstaged'
      call add(l:unstaged, l:item)
    elseif l:class == 'untracked'
      call add(l:untracked, l:item)
    endif
  endfor

  let l:lines = [
        \ '  GhostGit — ' . ghostgit#core#CurrentBranch(),
        \ '  ' . repeat('─', 40),
        \ ''
        \ ]

  if !empty(l:staged)
    call add(l:lines, 'Changes to be committed:')
    for l:item in l:staged
      call add(l:lines, '  ' . l:item.index . l:item.worktree . ' ' . l:item.file)
    endfor
    call add(l:lines, '')
  endif

  if !empty(l:unstaged)
    call add(l:lines, 'Changes not staged for commit:')
    for l:item in l:unstaged
      call add(l:lines, '  ' . l:item.index . l:item.worktree . ' ' . l:item.file)
    endfor
    call add(l:lines, '')
  endif

  if !empty(l:untracked)
    call add(l:lines, 'Untracked files:')
    for l:item in l:untracked
      call add(l:lines, '  ?? ' . l:item.file)
    endfor
    call add(l:lines, '')
  endif

  call extend(l:lines, [
        \ 'Help: s=stage, u=unstage, <cr>=diff, cc=commit, r=refresh, q=close',
        \ ''
        \ ])

  return l:lines
endfunction
