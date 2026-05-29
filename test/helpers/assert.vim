" ============================================================================
" ghostgit.vim - Test Assertions Helper
" ============================================================================

function! test#helpers#assert#Equals(actual, expected, ...) abort
  if a:actual ==# a:expected
    return 1
  endif

  let l:msg = get(a:000, 0, 'Expected ' . string(a:expected) . ' but got ' . string(a:actual))
  throw 'AssertionError: ' . l:msg
endfunction

function! test#helpers#assert#True(val, ...) abort
  if a:val
    return 1
  endif

  let l:msg = get(a:000, 0, 'Expected true but got ' . string(a:val))
  throw 'AssertionError: ' . l:msg
endfunction

function! test#helpers#assert#NotEmpty(val, ...) abort
  if !empty(a:val)
    return 1
  endif

  let l:msg = get(a:000, 0, 'Expected not empty')
  throw 'AssertionError: ' . l:msg
endfunction
