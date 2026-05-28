" ============================================================================
" ghostgit.vim - Diff Preview Buffer
" ============================================================================

function! ghostgit#diff#Open(file, ...) abort
  let l:extra_args = get(a:000, 0, '')
  let l:args = ['diff']

  if !empty(l:extra_args)
    call add(l:args, l:extra_args)
  endif

  call add(l:args, '--')
  call add(l:args, a:file)
  let l:lines = ghostgit#core#Run(l:args)

  call ghostgit#util#OpenBuffer('diff/' . a:file, 'botright')
  call ghostgit#util#Render(l:lines)

  setlocal nomodifiable
  nnoremap <silent><buffer> q :bd!<CR>
endfunction
