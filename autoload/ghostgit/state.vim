" ============================================================================
" ghostgit.vim - Global State Manager
" ============================================================================

" Initialize the global state for GhostGit
function! ghostgit#state#Init() abort
  if !exists('g:ghostgit_state')
    let g:ghostgit_state = {
          \ 'repos': {},
          \ 'buffers': {},
          \ 'version': '1.0'
          \ }
  endif
endfunction

" Ensure the global state is initialized
call ghostgit#state#Init()

" Add or initialize a repository entry in the state
function! ghostgit#state#SetRepo(root, ...) abort
  let l:data = get(a:000, 0, {})
  if !has_key(g:ghostgit_state.repos, a:root)
    let g:ghostgit_state.repos[a:root] = {
          \ 'branch': '',
          \ 'git_dir': '',
          \ 'last_refresh': 0,
          \ 'last_update': 0,
          \ 'cache': {}
          \ }
  endif
  if !empty(l:data)
    call extend(g:ghostgit_state.repos[a:root], l:data)
  endif
endfunction

" Retrieve repository information from state
function! ghostgit#state#GetRepo(...) abort
  let l:root = a:0 > 0 ? a:1 : ghostgit#core#RepoRoot()
  return get(g:ghostgit_state.repos, l:root, {})
endfunction

" Register a buffer in the state manager
function! ghostgit#state#SetBuffer(name, type, ...) abort
  let l:bufnr = get(a:000, 0, bufnr('%'))
  let g:ghostgit_state.buffers[a:name] = {
        \ 'bufnr': l:bufnr,
        \ 'type': a:type,
        \ 'items': [],
        \ 'view': {},
        \ 'created': localtime()
        \ }
endfunction

" Set arbitrary data for the current buffer
function! ghostgit#state#SetBufferData(name, data) abort
  let b:ghostgit_data = a:data
endfunction

" Get arbitrary data for a buffer
function! ghostgit#state#GetBufferData(name) abort
  let l:bufnr = bufnr('ghostgit://' . a:name)
  if l:bufnr == -1 | return {} | endif
  return getbufvar(l:bufnr, 'ghostgit_data', {})
endfunction

" Retrieve buffer information (from global state)
function! ghostgit#state#GetBuffer(name) abort
  return get(g:ghostgit_state.buffers, a:name, {})
endfunction

" Remove a buffer from state by bufnr
function! ghostgit#state#RemoveBuffer(bufnr) abort
  let l:names = []
  for [l:name, l:buf] in items(g:ghostgit_state.buffers)
    if l:buf.bufnr == a:bufnr
      call add(l:names, l:name)
    endif
  endfor
  for l:name in l:names
    unlet g:ghostgit_state.buffers[l:name]
  endfor
endfunction

" Get buffer info by bufnr
function! ghostgit#state#GetBufferByBufnr(bufnr) abort
  for [l:name, l:buf] in items(g:ghostgit_state.buffers)
    if l:buf.bufnr == a:bufnr
      return extend({'name': l:name}, l:buf)
    endif
  endfor
  return {}
endfunction

" Clear all state
function! ghostgit#state#Clear() abort
  if !exists('g:ghostgit_state')
    call ghostgit#state#Init()
  endif
  let g:ghostgit_state.repos = {}
  let g:ghostgit_state.buffers = {}
endfunction

" List all buffer names
function! ghostgit#state#ListBuffers() abort
  return keys(g:ghostgit_state.buffers)
endfunction

" Cache items for a buffer
function! ghostgit#state#CacheItems(name, items) abort
  if has_key(g:ghostgit_state.buffers, a:name)
    let g:ghostgit_state.buffers[a:name].items = a:items
    let g:ghostgit_state.buffers[a:name].created = localtime()
  endif
endfunction

" Retrieve cached items for a buffer
function! ghostgit#state#GetCachedItems(name) abort
  return get(get(g:ghostgit_state.buffers, a:name, {}), 'items', [])
endfunction

" Save current window view for a buffer
function! ghostgit#state#SaveView(name) abort
  let b:ghostgit_view = winsaveview()
endfunction

" Restore saved window view for a buffer
function! ghostgit#state#RestoreView(name) abort
  if exists('b:ghostgit_view') && !empty(b:ghostgit_view)
    call winrestview(b:ghostgit_view)
  endif
endfunction
