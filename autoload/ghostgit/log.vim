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

  " Cancel pending jobs when the buffer is wiped
  augroup GhostGitLogCleanup
    autocmd! * <buffer>
    autocmd BufWipeout <buffer> call ghostgit#job#CancelBuffer(str2nr(expand('<abuf>')))
  augroup END

  call ghostgit#log#Refresh()
endfunction

" Refresh log content (async via job queue)
function! ghostgit#log#Refresh() abort
  call ghostgit#state#SaveView('log')

  let l:repo_root = ghostgit#core#RepoRoot()
  if empty(l:repo_root)
    return
  endif

  let l:bufnr = bufnr('ghostgit://log')
  if l:bufnr == -1
    return
  endif

  call ghostgit#job#Debounce('log', 200, ['git', 'log', '--oneline', '--decorate', '--graph', '-100'], {
        \ 'bufnr': l:bufnr,
        \ 'priority': 1,
        \ 'cwd': l:repo_root,
        \ 'on_success': {lines -> s:OnLogResult(lines)},
        \ 'on_failure': {err -> ghostgit#util#Error('Failed to get log')}
        \ })
endfunction

" Callback: parse, cache, and render log result into the buffer.
function! s:OnLogResult(lines) abort
  let l:bufnr = bufnr('ghostgit://log')
  if l:bufnr == -1
    return
  endif

  let l:items = filter(
        \ map(a:lines, 'ghostgit#parser#ParseLogLine(v:val)'),
        \ '!empty(v:val)')

  call ghostgit#state#CacheItems('log', l:items)
  let l:rendered = ghostgit#render#Log(l:items)

  let l:cur_win = winnr()
  let l:log_win = bufwinnr(l:bufnr)
  if l:log_win != -1
    execute l:log_win . 'wincmd w'
    setlocal modifiable noreadonly
    silent! %delete _
    call setline(1, l:rendered)
    setlocal nomodifiable readonly
    call ghostgit#state#RestoreView('log')
    execute l:cur_win . 'wincmd w'
  endif
endfunction

" Get commit hash at current cursor position
function! ghostgit#log#HashAtCursor() abort
  return matchstr(getline('.'), '\x\{7,\}')
endfunction

" View commit details
function! ghostgit#log#OpenCommit() abort
  let l:hash = ghostgit#log#HashAtCursor()
  if empty(l:hash)
    call ghostgit#util#Warn('No commit hash found at cursor')
    return
  endif

  " Use Execute to leverage its smart output handling
  call ghostgit#core#Execute('show ' . l:hash)
endfunction
