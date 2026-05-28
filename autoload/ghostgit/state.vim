" ============================================================================
" ghostgit.vim - Global State Manager
" ============================================================================

function! ghostgit#state#Init() abort
  if !exists('g:ghostgit_state')
    let g:ghostgit_state = {
          \ 'repos': {},
          \ 'buffers': {}
          \ }
  endif
endfunction

function! ghostgit#state#SetRepo(root) abort
  if !has_key(g:ghostgit_state.repos, a:root)
    let g:ghostgit_state.repos[a:root] = {
          \ 'branch': '',
          \ 'git_dir': '',
          \ 'last_refresh': 0
          \ }
  endif
endfunction

function! ghostgit#state#GetRepo(...) abort
  if a:0 > 0
    return get(g:ghostgit_state.repos, a:1, {})
  endif
  return get(g:ghostgit_state.repos, ghostgit#core#RepoRoot(), {})
endfunction

function! ghostgit#state#SetBuffer(name, type) abort
  let l:bufnr = bufnr('%')
  let g:ghostgit_state.buffers[a:name] = {
        \ 'bufnr': l:bufnr,
        \ 'type': a:type,
        \ 'view': {},
        \ 'items': [],
        \ 'repo_root': ghostgit#core#RepoRoot()
        \ }
endfunction

function! ghostgit#state#GetBuffer(name) abort
  return get(g:ghostgit_state.buffers, a:name, {})
endfunction

function! ghostgit#state#RemoveBuffer(bufnr) abort
  for l:key in keys(g:ghostgit_state.buffers)
    if g:ghostgit_state.buffers[l:key].bufnr == a:bufnr
      call remove(g:ghostgit_state.buffers, l:key)
    endif
  endfor
endfunction

function! ghostgit#state#CacheItems(name, items) abort
  let l:buf = ghostgit#state#GetBuffer(a:name)
  if !empty(l:buf)
    let l:buf.items = a:items
  endif
endfunction

function! ghostgit#state#GetCachedItems(name) abort
  let l:buf = ghostgit#state#GetBuffer(a:name)
  return get(l:buf, 'items', [])
endfunction

function! ghostgit#state#SaveView(name) abort
  let l:buf = ghostgit#state#GetBuffer(a:name)
  if !empty(l:buf)
    let l:buf.view = winsaveview()
  endif
endfunction

function! ghostgit#state#RestoreView(name) abort
  let l:buf = ghostgit#state#GetBuffer(a:name)
  if !empty(l:buf) && !empty(l:buf.view)
    call winrestview(l:buf.view)
  endif
endfunction
