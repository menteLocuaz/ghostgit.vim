" ============================================================================
" ghostgit.vim - Git Output Parser
" ============================================================================

function! ghostgit#parser#ParseStatusLine(line) abort
  let l:index    = a:line[0]
  let l:worktree = a:line[1]
  let l:file     = a:line[3:]

  return {
        \ 'index': l:index,
        \ 'worktree': l:worktree,
        \ 'file': l:file
        \ }
endfunction

function! ghostgit#parser#Classify(item) abort
  if a:item.index == '?' | return 'untracked' | endif
  if a:item.index != ' ' | return 'staged'    | endif
  if a:item.worktree != ' ' | return 'unstaged' | endif
  return 'unmodified'
endfunction
