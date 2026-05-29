" ============================================================================
" ghostgit.vim - Branch Management
" ============================================================================

function! ghostgit#branch#Open() abort
  if !ghostgit#core#IsRepo()
    call ghostgit#util#Error('Not in a git repository')
    return
  endif

  let l:branches = ghostgit#core#ListBranches()
  let l:lines = ghostgit#render#Branches(l:branches)
  
  call ghostgit#util#OpenBuffer('branch')
  call ghostgit#state#SetBuffer('branch', 'branch')
  call ghostgit#util#Render(l:lines)
  
  nnoremap <silent><buffer> <cr> :call ghostgit#branch#Checkout()<CR>
  nnoremap <silent><buffer> q :bd!<CR>
endfunction

function! ghostgit#branch#Checkout() abort
  let l:line = getline('.')
  let l:branch = substitute(l:line, '^[ *]\s*', '', '')
  
  if empty(l:branch) | return | endif
  
  call ghostgit#git#Checkout(l:branch)
  call ghostgit#util#Info('Checked out: ' . l:branch)
  bd!
endfunction
