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

  " Refresh buffer contents asíncronamente
  call ghostgit#status#Refresh()
endfunction

" Refresh the contents of the status buffer (synchronous)
function! ghostgit#status#Refresh() abort
  " Save current position in buffer
  call ghostgit#state#SaveView('status')

  " Get repo root explicitly to avoid getcwd() issues in scratch buffers
  let l:repo_root = ghostgit#core#RepoRoot()
  if empty(l:repo_root)
    return
  endif

  " Get status synchronously
  let l:raw_lines = ghostgit#git#Status(l:repo_root)

  " Parse status items
  let l:items = map(l:raw_lines, 'ghostgit#parser#ParseStatusLine(v:val)')

  " Cache items for later use
  call ghostgit#state#CacheItems('status', l:items)
  
  " Render content
  let l:lines = ghostgit#render#Status(l:items)
  call ghostgit#util#Render(l:lines)
  
  " Restore position in buffer
  call ghostgit#state#RestoreView('status')
endfunction

" Add file to stage
function! ghostgit#status#Stage() abort
  " Get item under cursor
  let l:item = s:GetItemAtCursor()
  if empty(l:item) 
    call ghostgit#util#Warn('No file selected')
    return
  endif

  " Run git add
  call ghostgit#git#Add(l:item.file)
  call ghostgit#status#Refresh()
endfunction

" Remove file from stage
function! ghostgit#status#Unstage() abort
  " Get item under cursor
  let l:item = s:GetItemAtCursor()
  if empty(l:item) 
    call ghostgit#util#Warn('No file selected')
    return
  endif

  " Run git reset
  call ghostgit#git#Reset(l:item.file)
  call ghostgit#status#Refresh()
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
