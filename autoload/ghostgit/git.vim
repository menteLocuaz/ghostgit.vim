" ============================================================================
" ghostgit.vim - Git API Wrappers
" ============================================================================

function! ghostgit#git#Status(...) abort
  let l:cwd = get(a:000, 0, '')
  return ghostgit#core#Run(['status', '--short', '--branch'], l:cwd)
endfunction


function! ghostgit#git#Log(...) abort
  let l:cwd = get(a:000, 0, '')
  return ghostgit#core#Run([
        \ 'log',
        \ '--oneline',
        \ '--decorate',
        \ '--graph',
        \ '-50'
        \ ], l:cwd)
endfunction


function! ghostgit#git#Diff(...) abort
  let l:cwd = get(a:000, 0, '')
  return ghostgit#core#Run(['diff'], l:cwd)
endfunction


function! ghostgit#git#Blame(file, ...) abort
  let l:cwd = get(a:000, 0, '')
  return ghostgit#core#Run(['blame', '--porcelain', a:file], l:cwd)
endfunction


function! ghostgit#git#Add(file, ...) abort
  let l:cwd = get(a:000, 0, '')
  return ghostgit#core#Run(['add', a:file], l:cwd)
endfunction


function! ghostgit#git#Reset(file, ...) abort
  let l:cwd = get(a:000, 0, '')
  return ghostgit#core#Run(['reset', 'HEAD', a:file], l:cwd)
endfunction
