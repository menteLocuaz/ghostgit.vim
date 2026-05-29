" ============================================================================
" ghostgit.vim - Log Viewer
" ============================================================================

" Open the log viewer buffer
function! ghostgit#log#Open() abort
  if !ghostgit#core#IsRepo()
    call ghostgit#util#Error('Not in a git repository')
    return
  endif

  call ghostgit#util#OpenBuffer('log')
  call ghostgit#state#SetBuffer('log', 'log')
  call ghostgit#log#Refresh()
endfunction

" Refresh log content (synchronous via core#Run)
function! ghostgit#log#Refresh() abort
  call ghostgit#state#SaveView('log')

  let l:repo_root = ghostgit#core#RepoRoot()
  if empty(l:repo_root)
    return
  endif

  let l:raw_lines = ghostgit#git#Log(l:repo_root)
  if empty(l:raw_lines)
    call ghostgit#util#Render(ghostgit#render#Log([]))
    return
  endif

  let l:items = filter(
        \ map(l:raw_lines, 'ghostgit#parser#ParseLogLine(v:val)'),
        \ '!empty(v:val)')

  call ghostgit#state#CacheItems('log', l:items)
  call ghostgit#util#Render(ghostgit#render#Log(l:items))
  call ghostgit#state#RestoreView('log')
endfunction

" Get commit hash at current cursor position
function! ghostgit#log#HashAtCursor() abort
  return matchstr(getline('.'), '\x\{7,\}')
endfunction

" View commit details (placeholder)
function! ghostgit#log#OpenCommit() abort
  let l:hash = ghostgit#log#HashAtCursor()
  if empty(l:hash) | return | endif
  call ghostgit#util#Info('Commit: ' . l:hash)
endfunction
