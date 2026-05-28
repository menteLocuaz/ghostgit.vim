" ============================================================================
" ghostgit.vim - Status Buffer
" ============================================================================

function! ghostgit#status#Open() abort
  if !ghostgit#core#IsRepo()
    call ghostgit#util#Error('Not in a git repository')
    return
  endif

  call ghostgit#util#OpenBuffer('status')
  call ghostgit#status#Refresh()

  " Local keymaps
  nnoremap <silent><buffer> <cr> :call ghostgit#status#OpenFile()<CR>
  nnoremap <silent><buffer> s      :call ghostgit#status#Stage()<CR>
  nnoremap <silent><buffer> u      :call ghostgit#status#Unstage()<CR>
  nnoremap <silent><buffer> cc     :call ghostgit#status#Commit()<CR>
  nnoremap <silent><buffer> r      :call ghostgit#status#Refresh()<CR>
  nnoremap <silent><buffer> ?      :call ghostgit#status#ShowHelp()<CR>
endfunction


function! ghostgit#status#Refresh() abort
  let l:root = ghostgit#core#RepoRoot()
  let l:branch = ghostgit#core#CurrentBranch()

  let l:lines = ghostgit#git#Status(l:root)

  let l:header = [
        \ 'GhostGit — ' . l:branch,
        \ repeat('─', 50),
        \ '',
        \ ]

  let l:footer = [
        \ '',
        \ 'Shortcuts:',
        \ '  <cr> = diff    s = stage    u = unstage    cc = commit',
        \ '  r = refresh   q = quit     ? = help',
        \ ]

  call ghostgit#util#Render(l:header + l:lines + l:footer)
  normal! gg
endfunction


function! ghostgit#status#Stage() abort
  let l:line = getline('.')
  let l:file = s:ParseFile(l:line)
  if empty(l:file) | return | endif

  call ghostgit#git#Add(l:file)
  call ghostgit#util#Info('staged: ' . l:file)
  call ghostgit#status#Refresh()
endfunction


function! ghostgit#status#Unstage() abort
  let l:line = getline('.')
  let l:file = s:ParseFile(l:line)
  if empty(l:file) | return | endif

  call ghostgit#git#Reset(l:file)
  call ghostgit#util#Info('unstaged: ' . l:file)
  call ghostgit#status#Refresh()
endfunction


function! ghostgit#status#OpenFile() abort
  let l:line = getline('.')
  let l:file = s:ParseFile(l:line)
  if empty(l:file) | return | endif

  let l:path = ghostgit#core#RepoRoot() . '/' . l:file
  if filereadable(l:path)
    execute 'edit ' . fnameescape(l:path)
  endif
endfunction


function! ghostgit#status#Commit() abort
  call ghostgit#commit#Open()
endfunction


function! ghostgit#status#ShowHelp() abort
  echohl MoreMsg
  echom 'GhostGit Status Help:'
  echom '<cr> - diff file'
  echom 's - stage file'
  echom 'u - unstage file'
  echom 'cc - commit staged changes'
  echom 'r - refresh'
  echom 'q - quit'
  echohl None
endfunction


" Parse file from status line
function! s:ParseFile(line) abort
  let l:match = matchstr(a:line, '^[ MADRCU?!]\{2}\s*\zs.*')
  return substitute(l:match, '^[ *]', '', '')
endfunction
