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

  "Refresh buffer contents
  call ghostgit#status#Refresh()
<<<<<<< HEAD

  " Configure key mappings
  nnoremap <silent><buffer> <cr> :call ghostgit#status#Diff()<CR>
  nnoremap <silent><buffer> s    :call ghostgit#status#Stage()<CR>
  nnoremap <silent><buffer> u    :call ghostgit#status#Unstage()<CR>
  nnoremap <silent><buffer> cc   :call ghostgit#status#Commit()<CR>
  nnoremap <silent><buffer> ca   :call ghostgit#status#Amend()<CR>
  nnoremap <silent><buffer> r    :call ghostgit#status#Refresh()<CR>
  nnoremap <silent><buffer> q    :bd!<CR>

  " Add help information to the status bar
  setlocal statusline=[GhostGit]\ Status\ %f\ %=%l/%L 
=======
>>>>>>> 26e876c (feat(log): implement :GLog with parser, renderer, and buffer lifecycle)
endfunction

" Refresh the contents of the state buffer
function! ghostgit#status#Refresh() abort
<<<<<<< HEAD
  " Save current position in buffer
=======
  let l:bufnr = bufnr('%')
>>>>>>> 26e876c (feat(log): implement :GLog with parser, renderer, and buffer lifecycle)
  call ghostgit#state#SaveView('status')
  call ghostgit#util#Render(['  Loading...'])

<<<<<<< HEAD
  " Get state from git and parse it
  let l:raw_lines = ghostgit#git#Status()
  let l:items = map(l:raw_lines, 'ghostgit#parser#ParseStatusLine(v:val)')

  " Cache items for later use
  call ghostgit#state#CacheItems('status', l:items)

  " Render content
  let l:lines = ghostgit#render#Status(l:items)
=======
  let l:Callback = { lines, code -> s:OnRefreshComplete(l:bufnr, lines, code) }
  call ghostgit#git#Status(l:Callback)
endfunction

function! s:OnRefreshComplete(bufnr, raw_lines, exit_code) abort
  if a:exit_code != 0 && a:exit_code != -1 | return | endif
  if !bufexists(a:bufnr) | return | endif

  let l:items = map(a:raw_lines, 'ghostgit#parser#ParseStatusLine(v:val)')

  " Execute within the context of the target buffer
  call s:ExecuteInBuffer(a:bufnr, { -> s:UpdateBuffer('status', l:items) })
endfunction

function! s:UpdateBuffer(name, items) abort
  call ghostgit#state#CacheItems(a:name, a:items)
  let l:lines = ghostgit#render#Status(a:items)
>>>>>>> 26e876c (feat(log): implement :GLog with parser, renderer, and buffer lifecycle)
  call ghostgit#util#Render(l:lines)
  call ghostgit#state#RestoreView(a:name)
endfunction

<<<<<<< HEAD
  " Restore position in buffer
  call ghostgit#state#RestoreView('status')
  
  " Display update message
  call ghostgit#util#Info('Status refreshed')
=======
function! s:ExecuteInBuffer(bufnr, callback) abort
  let l:winid = bufwinid(a:bufnr)
  if l:winid != -1
    let l:prev_win = win_getid()
    call win_gotoid(l:winid)
    call a:callback()
    call win_gotoid(l:prev_win)
  else
    " Buffer is hidden, use setbufline or similar if needed, 
    " but for now we only render if visible or just skip
  endif
>>>>>>> 26e876c (feat(log): implement :GLog with parser, renderer, and buffer lifecycle)
endfunction

" Add file to stage
function! ghostgit#status#Stage() abort
" Get item under cursor
  let l:item = s:GetItemAtCursor()
  if empty(l:item) 
    call ghostgit#util#Warn('No file selected')
    return
  endif

try 
  " Run git add
  call ghostgit#git#Add(l:item.file)
  call ghostgit#status#Refresh()
  call ghostgit#util#Info('Staged: ' . l:item.file)
catch
  call ghostgit#util#Error('Failed to stage: ' . l:item.file)
endtry
endfunction

" Remove file from stage
function! ghostgit#status#Unstage() abort
  " Get item under cursor
  let l:item = s:GetItemAtCursor()
  if empty(l:item) 
    call ghostgit#util#Warn('No file selected')
    return
  endif

  try
    "Run git reset
    call ghostgit#git#Reset(l:item.file)
    call ghostgit#status#Refresh()
    call ghostgit#util#Info('Unstaged: ' . l:item.file)
  catch
    call ghostgit#util#Error('Failed to unstage: ' . l:item.file)
  endtry
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
  " Verify that there are files in staging
  let l:staged = ghostgit#git#GetStagedFiles()
  if len(l:staged) == 0
    call ghostgit#util#Warn('No staged files to commit')
    return
  endif

  call ghostgit#commit#Open()
endfunction

" Perform commit --amend
function! ghostgit#status#Amend() abort
  " Verify that there are files in staging or allow amend without changes
  let l:staged = ghostgit#git#GetStagedFiles()
  if len(l:staged) == 0
    let l:confirm = input('No staged files. Amend last commit anyway? (y/N): ')
    if l:confirm !~? '^y'
      return
    endif
  endif

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
