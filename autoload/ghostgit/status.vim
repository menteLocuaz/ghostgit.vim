" ============================================================================
" ghostgit.vim - Status Buffer Controller
" ============================================================================

function! ghostgit#status#Open() abort
  if !ghostgit#core#IsRepo()
    call ghostgit#util#Error('Not in a git repository')
    return
  endif

  call ghostgit#util#OpenBuffer('status')
  call ghostgit#state#SetBuffer('status', 'status')
  call ghostgit#status#Refresh()

  nnoremap <silent><buffer> <cr> :call ghostgit#status#Diff()<CR>
  nnoremap <silent><buffer> s    :call ghostgit#status#Stage()<CR>
  nnoremap <silent><buffer> u    :call ghostgit#status#Unstage()<CR>
  nnoremap <silent><buffer> cc   :call ghostgit#status#Commit()<CR>
  nnoremap <silent><buffer> r    :call ghostgit#status#Refresh()<CR>
  nnoremap <silent><buffer> q    :bd!<CR>
endfunction

function! ghostgit#status#Refresh() abort
  call ghostgit#state#SaveView('status')

  let l:raw_lines = ghostgit#git#Status()
  let l:items = map(l:raw_lines, 'ghostgit#parser#ParseStatusLine(v:val)')

  call ghostgit#state#CacheItems('status', l:items)

  let l:lines = ghostgit#render#Status(l:items)
  call ghostgit#util#Render(l:lines)

  call ghostgit#state#RestoreView('status')
endfunction

function! ghostgit#status#Stage() abort
  let l:item = s:GetItemAtCursor()
  if empty(l:item) | return | endif

  call ghostgit#git#Add(l:item.file)
  call ghostgit#status#Refresh()
endfunction

function! ghostgit#status#Unstage() abort
  let l:item = s:GetItemAtCursor()
  if empty(l:item) | return | endif

  call ghostgit#git#Reset(l:item.file)
  call ghostgit#status#Refresh()
endfunction

function! ghostgit#status#Diff() abort
  let l:item = s:GetItemAtCursor()
  if empty(l:item) | return | endif

  let l:class = ghostgit#parser#Classify(l:item)
  if l:class == 'staged'
    call ghostgit#diff#Open(l:item.file, '--cached')
  elseif l:class == 'unstaged'
    call ghostgit#diff#Open(l:item.file)
  else
    call ghostgit#util#Info('No diff for untracked files')
  endif
endfunction

function! ghostgit#status#Commit() abort
  call ghostgit#commit#Open()
endfunction

function! s:GetItemAtCursor() abort
  let l:line = getline('.')
  if l:line =~ '^\s*[#─]' || empty(l:line)
    return {}
  endif
  return ghostgit#parser#ParseStatusLine(l:line)
endfunction
