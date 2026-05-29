" ============================================================================
" ghostgit.vim - Global State Manager
" ============================================================================

" Initialize the global state for GhostGit
function! ghostgit#state#Init() abort
  if !exists('g:ghostgit_state')
    let g:ghostgit_state = {
          \ 'repos': {},
          \ 'buffers': {}
          \ }
  endif
endfunction

" Ensure the global state is initialized
call ghostgit#state#Init()

" Add or initialize a repository entry in the state
" @param {string} root - Repository root path
function! ghostgit#state#SetRepo(root) abort
  " Validate input
  if empty(a:root)
    throw 'ghostgit: Repository root path cannot be empty'
  endif

  " Initialize repo entry if it doesn't exist
  if !has_key(g:ghostgit_state.repos, a:root)
    let g:ghostgit_state.repos[a:root] = {
          \ 'branch': '',
          \ 'git_dir': '',
          \ 'last_refresh': 0
          \ }
  endif
endfunction

" Retrieve repository information from state
" @param {...string} root - Optional repository root path
" @return {dict} Repository information or empty dict
function! ghostgit#state#GetRepo(...) abort
  " Use provided root or get current repo root
  let l:root = a:0 > 0 ? a:1 : ghostgit#core#RepoRoot()
  
  " Return repository info or empty dict
  return get(g:ghostgit_state.repos, l:root, {})
endfunction

" Register a buffer in the state manager
" @param {string} name - Buffer identifier
" @param {string} type - Buffer type
function! ghostgit#state#SetBuffer(name, type) abort
  " Validate inputs
  if empty(a:name)
    throw 'ghostgit: Buffer name cannot be empty'
  endif
  
  if empty(a:type)
    throw 'ghostgit: Buffer type cannot be empty'
  endif

  " Register buffer with current buffer number
  let l:bufnr = bufnr('%')
  let g:ghostgit_state.buffers[a:name] = {
        \ 'bufnr': l:bufnr,
        \ 'type': a:type,
        \ 'view': {},
        \ 'items': [],
        \ 'repo_root': ghostgit#core#RepoRoot()
        \ }
endfunction

" Retrieve buffer information from state
" @param {string} name - Buffer identifier
" @return {dict} Buffer information or empty dict
function! ghostgit#state#GetBuffer(name) abort
  " Validate input
  if empty(a:name)
    return {}
  endif

  return get(g:ghostgit_state.buffers, a:name, {})
endfunction

" Remove buffer from state by buffer number
" @param {number} bufnr - Buffer number
function! ghostgit#state#RemoveBuffer(bufnr) abort
  " Validate input
  if a:bufnr < 0
    return
  endif

  " Find and remove buffer entry
  for l:key in keys(g:ghostgit_state.buffers)
    if get(g:ghostgit_state.buffers[l:key], 'bufnr', -1) == a:bufnr
      call remove(g:ghostgit_state.buffers, l:key)
      break
    endif
  endfor
endfunction

" Cache items for a buffer
" @param {string} name - Buffer identifier
" @param {list} items - Items to cache
function! ghostgit#state#CacheItems(name, items) abort
  " Get buffer and validate
  let l:buf = ghostgit#state#GetBuffer(a:name)
  if empty(l:buf)
    return
  endif

  " Update cached items
  let l:buf.items = a:items
endfunction

" Retrieve cached items for a buffer
" @param {string} name - Buffer identifier
" @return {list} Cached items or empty list
function! ghostgit#state#GetCachedItems(name) abort
  " Get buffer and extract items
  let l:buf = ghostgit#state#GetBuffer(a:name)
  return get(l:buf, 'items', [])
endfunction

" Save current window view for a buffer
" @param {string} name - Buffer identifier
function! ghostgit#state#SaveView(name) abort
  " Get buffer and validate
  let l:buf = ghostgit#state#GetBuffer(a:name)
  if empty(l:buf)
    return
  endif

  " Save current window view
  let l:buf.view = winsaveview()
endfunction

" Restore saved window view for a buffer
" @param {string} name - Buffer identifier
function! ghostgit#state#RestoreView(name) abort
  " Get buffer and validate
  let l:buf = ghostgit#state#GetBuffer(a:name)
  if empty(l:buf) || empty(l:buf.view)
    return
  endif

  " Restore saved window view
  call winrestview(l:buf.view)
endfunction