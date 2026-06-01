" ============================================================================
" ghostgit.vim - Remote Operations
" ============================================================================

" Global variables for configurations
if !exists('g:ghostgit_remote_preferred')
  let g:ghostgit_remote_preferred = 'origin'
endif

if !exists('g:ghostgit_remote_timeout')
  let g:ghostgit_remote_timeout = 10
endif

" Open a file (or repo root) on the remote in the browser.
" line1, line2 - line range from visual mode (or current line)
" a:000[0] - optional file path (default: current buffer; empty = repo root)
" a:000[1] - optional remote name (default: g:ghostgit_remote_preferred)
function! ghostgit#remote#Browse(line1, line2, ...) abort
  if !ghostgit#core#IsRepo()
    call ghostgit#util#Error('Not in a git repository')
    return
  endif

  let l:file = get(a:000, 0, '')
  let l:remote_name = get(a:000, 1, g:ghostgit_remote_preferred)

  if empty(l:file)
    " Default to current buffer
    let l:file = expand('%:p')
  endif

  " Get the remote URL
  let l:base_url = ghostgit#remote#GetRemoteURL(l:remote_name)
  if empty(l:base_url)
    if l:remote_name != g:ghostgit_remote_preferred
      call ghostgit#util#Warn('Remote "' . l:remote_name . '" not found, trying "' . g:ghostgit_remote_preferred . '"')
      let l:base_url = ghostgit#remote#GetRemoteURL(g:ghostgit_remote_preferred)
    endif
    if empty(l:base_url)
      call ghostgit#util#Error('Could not find remote URL for "' . l:remote_name . '"')
      return
    endif
  endif

  " Resolve file path relative to repo root
  let l:repo_root = ghostgit#core#RepoRoot()
  let l:current_file = l:file
  if l:current_file !~# '^/'
    let l:current_file = fnamemodify(l:current_file, ':p')
  endif

  if !empty(l:current_file) && !empty(l:repo_root)
    let l:relative_path = substitute(l:current_file, escape(l:repo_root, '\'), '', '')
    let l:relative_path = substitute(l:relative_path, '^/', '', '')
    if l:relative_path ==# l:current_file
      let l:relative_path = fnamemodify(l:current_file, ':t')
    endif
  else
    let l:relative_path = ''
  endif

  " Get branch or commit hash
  let l:branch = ghostgit#core#CurrentBranch()
  let l:commit_hash = ''
  if l:branch =~# '^HEAD detached'
    let l:hash_result = ghostgit#core#Run(['rev-parse', 'HEAD'])
    if !empty(l:hash_result)
      let l:commit_hash = l:hash_result[0]
    endif
  endif

  " Build file URL
  let l:file_url = ghostgit#remote#BuildFileURL(l:base_url, l:relative_path, l:branch, l:commit_hash)
  if empty(l:file_url)
    call ghostgit#util#Error('Could not construct file URL')
    return
  endif

  " Append line range from visual mode
  if a:line1 > 0
    let l:file_url .= ghostgit#remote#LineRangeSuffix(l:base_url, a:line1, a:line2)
  endif

  call ghostgit#remote#OpenURL(l:file_url)
endfunction

" Open the current file in the browser (legacy wrapper)
function! ghostgit#remote#BrowseFile(...) abort
  let l:args = [line('.'), line('.')]
  if a:0 > 0
    call add(l:args, expand('%:p'))
    call add(l:args, a:1)
  endif
  call call('ghostgit#remote#Browse', l:args)
endfunction

" Get the URL of a specific remote
function! ghostgit#remote#GetRemoteURL(remote_name, ...) abort
  let l:cwd = get(a:000, 0, '')
  " Verify that the remote exists
  let l:remotes = ghostgit#core#Run(['remote'], l:cwd, {'silent': 1})
  if empty(l:remotes) || index(l:remotes, a:remote_name) == -1
    return ''
  endif

  " Get remote URL
  let l:output = ghostgit#core#Run(['remote', 'get-url', a:remote_name], l:cwd, {'silent': 1})
  if empty(l:output)
    return ''
  endif

  let l:url = l:output[0]
  
  " Convert SSH URL to HTTP/HTTPS if necessary
  let l:url = ghostgit#remote#ConvertSSHToHTTP(l:url)
  
  return l:url
endfunction

" Convert SSH URL to HTTP/HTTPS
function! ghostgit#remote#ConvertSSHToHTTP(url) abort
  let l:url = a:url
  
  " git@github.com:user/repo.git -> https://github.com/user/repo
  if l:url =~# '^git@'
    let l:url = substitute(l:url, '^git@\(.\{-}\):', 'https://\1/', '')
    let l:url = substitute(l:url, '\.git$', '', '')
  endif
  
  " protocol://user@host/path -> protocol://host/path
  let l:url = substitute(l:url, '://[^@/]*@', '://', '')
  
  return l:url
endfunction

" Build URL for a specific file
function! ghostgit#remote#BuildFileURL(base_url, file_path, branch, commit_hash) abort
  let l:url = a:base_url
  let l:ref = !empty(a:commit_hash) ? a:commit_hash :
        \ (!empty(a:branch) && a:branch !~# '^HEAD detached' ? a:branch : 'HEAD')

  if l:url =~# 'github\.com'
    let l:url .= '/blob/' . l:ref
  elseif l:url =~# 'gitlab\.com'
    let l:url .= '/-/blob/' . l:ref
  elseif l:url =~# 'bitbucket\.org'
    let l:url .= '/src/' . l:ref
  elseif l:url =~# 'gitee\.com'
    let l:url .= '/blob/' . l:ref
  elseif l:url =~# 'pagure\.io'
    let l:url .= '/blob/' . l:ref . '/f'
  elseif l:url =~# 'git\.sr\.ht'
    let l:url .= '/tree/' . l:ref . '/item'
  else
    let l:url .= '/blob/' . l:ref
  endif

  if !empty(a:file_path)
    let l:url .= '/' . a:file_path
  endif

  return l:url
endfunction

" Append line range fragment per hosting provider
function! ghostgit#remote#LineRangeSuffix(url, line1, line2) abort
  if a:line1 <= 0 | return '' | endif

  let l:single = '#L' . a:line1
  let l:range  = '#L' . a:line1 . '-L' . a:line2

  if a:url =~# 'github\.com'
    return a:line1 == a:line2 ? l:single : '#L' . a:line1 . '-L' . a:line2
  elseif a:url =~# 'gitlab\.com'
    return a:line1 == a:line2 ? l:single : '#L' . a:line1 . '-' . a:line2
  elseif a:url =~# 'bitbucket\.org'
    return a:line1 == a:line2 ? '#lines-' . a:line1 : '#lines-' . a:line1 . ':' . a:line2
  elseif a:url =~# 'gitee\.com'
    return a:line1 == a:line2 ? l:single : '#L' . a:line1 . '-L' . a:line2
  elseif a:url =~# 'pagure\.io'
    return a:line1 == a:line2 ? '#_' . a:line1 : '#_' . a:line1 . '-' . a:line2
  elseif a:url =~# 'git\.sr\.ht'
    return a:line1 == a:line2 ? l:single : '#L' . a:line1 . '-' . a:line2
  else
    return a:line1 == a:line2 ? l:single : l:range
  endif
endfunction

" Open a URL in the default browser
function! ghostgit#remote#OpenURL(url) abort
  " Validate URL
  if empty(a:url) || a:url !~# '^\w\+://'
    call ghostgit#util#Error('Invalid URL: ' . a:url)
    return
  endif

  let l:cmd = ''
  let l:background = ''
  
  " Determine command according to platform
  if has('win32') || has('win64')
    let l:cmd = 'cmd /c start'
    " In Windows, 'start' requires a title as its first parameter
    let l:url_param = '"" ' . shellescape(a:url)
  elseif has('mac') || has('macunix')
    let l:cmd = 'open'
    let l:url_param = shellescape(a:url)
  else
    " Unix/Linux
    let l:cmd = 'xdg-open'
    let l:url_param = shellescape(a:url)
    let l:background = ' &'
  endif

  " Verify that the command exists
  if empty(l:cmd) || !executable(split(l:cmd)[0])
    call ghostgit#util#Error('Cannot find browser command')
    return
  endif

  call ghostgit#util#Info('Opening ' . a:url)
  
  " Execute command with error handling
  try
    let l:exit_code = system(l:cmd . ' ' . l:url_param . l:background)
    if v:shell_error != 0
      call ghostgit#util#Error('Failed to open browser (exit code: ' . v:shell_error . ')')
    endif
  catch
    call ghostgit#util#Error('Failed to open browser: ' . v:exception)
  endtry
endfunction

" List all available remotes
function! ghostgit#remote#List(...) abort
  let l:cwd = get(a:000, 0, '')

  " Verify that we are in a Git repository
  if !empty(l:cwd)
    if !ghostgit#core#IsRepo(l:cwd)
      call ghostgit#util#Error('Not a git repository')
      return []
    endif
  elseif !ghostgit#core#IsRepo()
    call ghostgit#util#Error('Not in a git repository')
    return []
  endif

  " Get list of remotes
  let l:remotes = ghostgit#core#Run(['remote'], l:cwd, {'silent': 1})
  if empty(l:remotes)
    call ghostgit#util#Info('No remotes found')
    return []
  endif

  " Get URL of each remote
  let l:remote_info = []
  for l:remote in l:remotes
    let l:url = ghostgit#remote#GetRemoteURL(l:remote, l:cwd)
    call add(l:remote_info, {'name': l:remote, 'url': l:url})
  endfor

  return l:remote_info
endfunction

" Display remote information in a special buffer
function! ghostgit#remote#Show() abort
  " Verify that we are in a Git repository
  if !ghostgit#core#IsRepo()
    call ghostgit#util#Error('Not in a git repository')
    return
  endif

  " Obtain information from remote locations
  let l:remotes = ghostgit#remote#List()
  if empty(l:remotes)
    return
  endif

  " Open or reuse the remotes buffer
  call ghostgit#util#OpenBuffer('remotes')
  setlocal nobuflisted

  " Build content lines
  let l:lines = ['# Git Remotes', '']
  for l:remote in l:remotes
    call add(l:lines, l:remote.name . ': ' . l:remote.url)
  endfor

  call ghostgit#util#Render(l:lines)

  " Configure mappings
  nnoremap <silent><buffer> <CR> :call ghostgit#remote#BrowseLine()<CR>
endfunction

" Open remote from current line
function! ghostgit#remote#BrowseLine() abort
  " Verify that we are in the remotes buffer
  if bufname('%') !~# '^ghostgit://remotes$'
    return
  endif

  " Get current line
  let l:line = getline('.')

  " Extract remote name and open its URL
  if l:line =~# '^[^:]\+:'
    let l:remote_name = split(l:line, ':')[0]
    let l:url = ghostgit#remote#GetRemoteURL(l:remote_name)
    if !empty(l:url)
      call ghostgit#remote#OpenURL(l:url)
    endif
  endif
endfunction

