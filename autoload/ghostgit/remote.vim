" ============================================================================
" ghostgit.vim - Remote Operations
" ============================================================================

" Open the current repository or file in the browser
function! ghostgit#remote#Browse() abort
  if !ghostgit#core#IsRepo()
    call ghostgit#util#Error('Not in a git repository')
    return
  endif

  " Get the remote URL
  let l:output = ghostgit#core#Run(['remote', 'get-url', 'origin'])
  if empty(l:output)
    call ghostgit#util#Error('Could not find remote origin')
    return
  endif

  let l:url = l:output[0]
  
  " Convert SSH URL to HTTP URL if necessary
  " git@github.com:user/repo.git -> https://github.com/user/repo
  if l:url =~# '^git@'
    let l:url = substitute(l:url, '^git@\(.\{-}\):', 'https://\1/', '')
    let l:url = substitute(l:url, '\.git$', '', '')
  endif

  call s:OpenURL(l:url)
endfunction

" Open a URL in the default browser
function! s:OpenURL(url) abort
  let l:cmd = ''
  if has('win32') || has('win64')
    let l:cmd = 'start'
  elseif has('mac') || has('macunix')
    let l:cmd = 'open'
  else
    let l:cmd = 'xdg-open'
  endif

  call ghostgit#util#Info('Opening ' . a:url)
  call system(l:cmd . ' ' . shellescape(a:url) . ' &')
endfunction
