" ============================================================================
" ghostgit.vim - Git Output Parser
" ============================================================================

" Parse a line from `git status --short`
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

" Classify a status item
function! ghostgit#parser#Classify(item) abort
  if a:item.index == '?' | return 'untracked' | endif
  if a:item.index != ' ' | return 'staged'    | endif
  if a:item.worktree != ' ' | return 'unstaged' | endif
  return 'unmodified'
endfunction

" Parse a line from `git log --oneline --graph`
function! ghostgit#parser#ParseLogLine(line) abort
  " Handle graph characters at the beginning
  let l:hash_match = matchlist(a:line, '^\([*|\\\/ ]*\)\(\x\{7,\}\)\s\+\(.*\)$')
  
  if !empty(l:hash_match)
    return {
          \ 'graph': l:hash_match[1],
          \ 'hash': l:hash_match[2],
          \ 'subject': l:hash_match[3]
          \ }
  endif

  " Fallback for non-graph lines or simple format
  let l:parts = split(a:line, '\s\+', 2)
  return {
        \ 'graph': '',
        \ 'hash': get(l:parts, 0, ''),
        \ 'subject': get(l:parts, 1, '')
        \ }
endfunction
