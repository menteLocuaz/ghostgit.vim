" ============================================================================
" ghostgit.vim - Status Buffer Controller
" ============================================================================

" Open the state buffer
function! ghostgit#status#Open() abort
  " Verify that we are in a git repository
  if !ghostgit#core#IsRepo()
    call ghostgit#util#Error('Not in a git repository')
    return
  endif

  " Create or open the state buffer
  call ghostgit#util#OpenBuffer('status')
  call ghostgit#state#SetBuffer('status', 'status')

  " Cancel pending jobs when the buffer is wiped
  augroup GhostGitStatusCleanup
    autocmd! * <buffer>
    autocmd BufWipeout <buffer> call ghostgit#job#CancelBuffer(str2nr(expand('<abuf>')))
  augroup END

  " Refresh buffer contents asynchronously
  call ghostgit#status#Refresh()
endfunction

" Refresh the contents of the status buffer (async via job queue)
function! ghostgit#status#Refresh() abort
  call ghostgit#state#SaveView('status')

  let l:repo_root = ghostgit#core#RepoRoot()
  if empty(l:repo_root)
    return
  endif

  let l:bufnr = bufnr('ghostgit://status')
  if l:bufnr == -1
    return
  endif

  call ghostgit#job#Debounce('status', 200, ['git', 'status', '--short', '--branch'], {
        \ 'bufnr': l:bufnr,
        \ 'priority': 1,
        \ 'cwd': l:repo_root,
        \ 'on_success': {lines -> s:OnStatusResult(l:repo_root, lines)},
        \ 'on_failure': {err -> ghostgit#util#Error('Failed to get status')}
        \ })
endfunction

" Callback: parse, cache, and render status result into the buffer.
function! s:OnStatusResult(repo_root, lines) abort
  let l:bufnr = bufnr('ghostgit://status')
  if l:bufnr == -1
    return
  endif

  let l:status_data = ghostgit#parser#ParseStatusOutput(a:lines)
  
  " Update global repo state with branch info
  call ghostgit#state#SetRepo(a:repo_root, {
        \ 'branch': l:status_data.branch,
        \ 'upstream': l:status_data.upstream,
        \ 'ahead': l:status_data.ahead,
        \ 'behind': l:status_data.behind,
        \ 'last_refresh': localtime()
        \ })

  call ghostgit#state#CacheItems('status', l:status_data.items)
  let l:rendered = ghostgit#render#Status(l:status_data)

  " Render content non-disruptively
  call ghostgit#util#RenderToBuffer(l:bufnr, l:rendered)

  " Restore view if the buffer is visible in any window
  let l:winid = bufwinid(l:bufnr)
  if l:winid != -1
    let l:cur_win = win_getid()
    call win_gotoid(l:winid)
    call ghostgit#state#RestoreView('status')
    call win_gotoid(l:cur_win)
  endif
endfunction

" Add file to stage
function! ghostgit#status#Stage() abort
  " Get item under cursor
  let l:item = s:GetItemAtCursor()
  if empty(l:item) 
    call ghostgit#util#Warn('No file selected')
    return
  endif

  " Run git add asynchronously
  call ghostgit#git#Add(l:item.file, {
        \ 'on_exit': {job, code -> ghostgit#status#Refresh()}
        \ })
endfunction

" Remove file from stage
function! ghostgit#status#Unstage() abort
  " Get item under cursor
  let l:item = s:GetItemAtCursor()
  if empty(l:item) 
    call ghostgit#util#Warn('No file selected')
    return
  endif

  " Run git reset asynchronously
  call ghostgit#git#Reset(l:item.file, {
        \ 'on_exit': {job, code -> ghostgit#status#Refresh()}
        \ })
endfunction

" Open diff for the selected file
function! ghostgit#status#Diff() abort
  " Get item under cursor
  let l:item = s:GetItemAtCursor()
  if empty(l:item) 
    call ghostgit#util#Warn('No file selected')
    return
  endif

  " Determine diff type based on file state
  let l:class = ghostgit#parser#Classify(l:item)
  if l:class == 'staged'
    call ghostgit#diff#Open(l:item.file, '--cached')
  elseif l:class == 'unstaged'
    call ghostgit#diff#Open(l:item.file)
  else
    call ghostgit#util#Info('No diff for untracked files')
  endif
endfunction

" Open commit window
function! ghostgit#status#Commit() abort
  call ghostgit#commit#Open()
endfunction

" Perform commit --amend
function! ghostgit#status#Amend() abort
  call ghostgit#commit#Open('--amend')
endfunction

" Get item under cursor
function! s:GetItemAtCursor() abort
  " Get current line
  let l:line = getline('.')

  " Verify that it is not an empty or separator line
  if l:line =~ '^\s*[#─]' || empty(l:line)
    return {}
  endif

  " Parse status line
  return ghostgit#parser#ParseStatusLine(l:line)
endfunction
