" ============================================================================
" ghostgit.vim - Status Buffer
" ============================================================================

function! ghostgit#status#Open() abort
  if !ghostgit#core#IsRepo()
    call ghostgit#util#Error('No estás en un repositorio git')
    return
  endif

  call ghostgit#util#OpenBuffer('status')
  call ghostgit#status#Refresh()

  " Local status buffer mappings
  nnoremap <silent><buffer> r :call ghostgit#status#Refresh()<CR>
  nnoremap <silent><buffer> s :call ghostgit#status#StageFile()<CR>
  nnoremap <silent><buffer> u :call ghostgit#status#UnstageFile()<CR>
endfunction


function! ghostgit#status#Refresh() abort
  let l:root  = ghostgit#core#RepoRoot()
  let l:lines = ghostgit#git#Status(l:root)

  " Header info
  let l:branch = ghostgit#core#CurrentBranch(l:root)
  let l:header = ['  GhostGit — ' . l:branch, repeat('─', 40), '']

  call ghostgit#util#Render(l:header + l:lines)
endfunction


function! ghostgit#status#StageFile() abort
  let l:line = getline('.')
  let l:file = s:ExtractFilename(l:line)
  if empty(l:file) | return | endif

  call ghostgit#git#Add(l:file, ghostgit#core#RepoRoot())
  call ghostgit#util#Info('staged: ' . l:file)
  call ghostgit#status#Refresh()
endfunction


function! ghostgit#status#UnstageFile() abort
  let l:line = getline('.')
  let l:file = s:ExtractFilename(l:line)
  if empty(l:file) | return | endif

  call ghostgit#git#Reset(l:file, ghostgit#core#RepoRoot())
  call ghostgit#util#Info('unstaged: ' . l:file)
  call ghostgit#status#Refresh()
endfunction


" Extracts the file name from a line of `git status --short`
" Formato: 'XY filename' donde XY son 2 chars of status
function! s:ExtractFilename(line) abort
  let l:match = matchstr(a:line, '^\s*\S\S\s\+\zs.*')
  return trim(l:match)
endfunction
