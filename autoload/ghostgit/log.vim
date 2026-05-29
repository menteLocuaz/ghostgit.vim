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
  let l:bufnr = bufnr('%')
  call ghostgit#state#SaveView('log')
  call ghostgit#util#Render(['  Loading log...'])

  let l:Callback = { lines, code -> s:OnLogComplete(l:bufnr, lines, code) }
  call ghostgit#git#Log(l:Callback)
endfunction

function! s:OnLogComplete(bufnr, raw_lines, exit_code) abort
  if a:exit_code != 0 && a:exit_code != -1 | return | endif
  if !bufexists(a:bufnr) | return | endif

  let l:items = filter(
        \ map(a:raw_lines, 'ghostgit#parser#ParseLogLine(v:val)'),
        \ '!empty(v:val)')

  call s:ExecuteInBuffer(a:bufnr, { -> s:UpdateBuffer('log', l:items) })
endfunction

function! s:UpdateBuffer(name, items) abort
  call ghostgit#state#CacheItems(a:name, a:items)
  call ghostgit#util#Render(ghostgit#render#Log(a:items))
  call ghostgit#state#RestoreView(a:name)
endfunction

function! s:ExecuteInBuffer(bufnr, callback) abort
  let l:winid = bufwinid(a:bufnr)
  if l:winid != -1
    let l:prev_win = win_getid()
    call win_gotoid(l:winid)
    call a:callback()
    call win_gotoid(l:prev_win)
  endif
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
