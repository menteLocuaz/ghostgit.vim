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

" Open the current repository in your browser
function! ghostgit#remote#Browse(...) abort
  " Verify that we are in a Git repository
  if !ghostgit#core#IsRepo()
    call ghostgit#util#Error('Not in a git repository')
    return
  endif

  " Get remote name (default 'origin')
  let l:remote_name = get(a:000, 0, g:ghostgit_remote_preferred)
  
  " Get the remote URL
  let l:url = ghostgit#remote#GetRemoteURL(l:remote_name)
  if empty(l:url)
    " Try the default remote if another one was specified
    if l:remote_name != g:ghostgit_remote_preferred
      call ghostgit#util#Warn('Remote "' . l:remote_name . '" not found, trying "' . g:ghostgit_remote_preferred . '"')
      let l:url = ghostgit#remote#GetRemoteURL(g:ghostgit_remote_preferred)
    endif
    
    if empty(l:url)
      call ghostgit#util#Error('Could not find remote URL for "' . l:remote_name . '"')
      return
    endif
  endif

  " Open URL in browser
  call ghostgit#remote#OpenURL(l:url)
endfunction

" Open the current file in the browser (in the current commit or in the branch)
function! ghostgit#remote#BrowseFile(...) abort
  " Verify that we are in a Git repository
  if !ghostgit#core#IsRepo()
    call ghostgit#util#Error('Not in a git repository')
    return
  endif

  " Get remote name
  let l:remote_name = get(a:000, 0, g:ghostgit_remote_preferred)
  
  " Get the base URL of the remote
  let l:base_url = ghostgit#remote#GetRemoteURL(l:remote_name)
  if empty(l:base_url)
    call ghostgit#util#Error('Could not find remote URL')
    return
  endif

  " Get information about the current commit
  let l:branch = ghostgit#core#CurrentBranch()
  let l:commit_hash = ''
  
  " If we are in HEAD detached, get the hash
  if l:branch =~# '^HEAD detached'
    let l:hash_result = ghostgit#core#Run(['rev-parse', 'HEAD'])
    if !empty(l:hash_result)
      let l:commit_hash = l:hash_result[0]
    endif
  endif

  " Get relative path of the current file with respect to the root repository
  let l:repo_root = ghostgit#core#RepoRoot()
  let l:current_file = expand('%:p')
  
  if !empty(l:current_file) && !empty(l:repo_root)
    " Calculate relative path
    let l:relative_path = substitute(fnamemodify(l:current_file, ':.'), '\', '/', 'g')
    
    " If the file is outside the repo, use only the name
    if l:relative_path !~# '^' . escape(l:repo_root, '\') 
      let l:relative_path = fnamemodify(l:current_file, ':t')
    endif
  else
    let l:relative_path = ''
  endif

  " Build file URL
  let l:file_url = ghostgit#remote#BuildFileURL(l:base_url, l:relative_path, l:branch, l:commit_hash)
  
  if empty(l:file_url)
    call ghostgit#util#Error('Could not construct file URL')
    return
  endif

  " Open URL in browser
  call ghostgit#remote#OpenURL(l:file_url)
endfunction

" Get the URL of a specific remote
function! ghostgit#remote#GetRemoteURL(remote_name) abort
  " Verify that the remote exists
  let l:remotes = ghostgit#core#Run(['remote'], {'silent': 1})
  if empty(l:remotes) || index(l:remotes, a:remote_name) == -1
    return ''
  endif

  " Get remote URL
  let l:output = ghostgit#core#Run(['remote', 'get-url', a:remote_name], {'silent': 1})
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
  
  " protocolo://user@host/path -> protocolo://host/path
  let l:url = substitute(l:url, '://[^@/]*@', '://', '')
  
  return l:url
endfunction

" Build URL for a specific file
function! ghostgit#remote#BuildFileURL(base_url, file_path, branch, commit_hash) abort
  let l:url = a:base_url
  
  " Determine branch or commit to use
  let l:ref = !empty(a:commit_hash) ? a:commit_hash : 
             \ (!empty(a:branch) && a:branch !~# '^HEAD detached' ? a:branch : 'HEAD')
  
  " Support for different platforms
  if l:url =~# 'github\.com'
    " GitHub: https://github.com/user/repo/blob/branch/file
    let l:url .= '/blob/' . l:ref
  elseif l:url =~# 'gitlab\.com'
    " GitLab: https://gitlab.com/user/repo/-/blob/branch/file
    let l:url .= '/-/blob/' . l:ref
  elseif l:url =~# 'bitbucket\.org'
    " Bitbucket: https://bitbucket.org/user/repo/src/branch/file
    let l:url .= '/src/' . l:ref
  else
    " By default, assume a structure similar to GitHub
    let l:url .= '/blob/' . l:ref
  endif
  
  " Agregar ruta del archivo si existe
  if !empty(a:file_path)
    let l:url .= '/' . a:file_path
  endif
  
  return l:url
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
function! ghostgit#remote#List() abort
  " Verify that we are in a Git repository
  if !ghostgit#core#IsRepo()
    call ghostgit#util#Error('Not in a git repository')
    return []
  endif

  " Get list of remotes
  let l:remotes = ghostgit#core#Run(['remote'], {'silent': 1})
  if empty(l:remotes)
    call ghostgit#util#Info('No remotes found')
    return []
  endif

  " Get URL of each remote
  let l:remote_info = []
  for l:remote in l:remotes
    let l:url = ghostgit#remote#GetRemoteURL(l:remote)
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

  " Create a special buffer to display remotes
  let l:bufname = 'ghostgit://remotes'
  let l:bufnr = bufnr(l:bufname)
  
  if l:bufnr == -1
    execute 'botright new ' . l:bufname
  else
    execute 'buffer ' . l:bufnr
  endif
  
  " Configure buffer
  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal noswapfile
  setlocal nobuflisted
  setlocal nomodifiable
  setlocal filetype=git
  
  " Make temporarily modifiable
  setlocal modifiable
  
  " Clear buffer
  silent %delete _
  
  " Insert remote information
  call append(0, '# Git Remotes')
  call append(1, '')
  
  let l:line_num = 2
  for l:remote in l:remotes
    call append(l:line_num, l:remote.name . ': ' . l:remote.url)
    let l:line_num += 1
  endfor
  
  " Remove extra blank line
  if getline('$') == ''
    silent $delete _
  endif
  
  " To become unchangeable again
  setlocal nomodifiable
  
  " Go to start
  normal! gg
  
  " Configure mappings
  nnoremap <silent><buffer> <CR> :call ghostgit#remote#BrowseLine()<CR>
  nnoremap <silent><buffer> q :bd!<CR>
endfunction

" Open remote from current line
function! ghostgit#remote#BrowseLine() abort
  " Verificar que estamos en el buffer correcto
  if bufname('%') !~# '^ghostgit://remotes$'
    return
  endif
  
  " Get current line
  let l:line = getline('.')
  
  " Extract remote name
  if l:line =~# '^[^:]\+:'
    let l:remote_name = split(l:line, ':')[0]
    call ghostgit#remote#Browse(l:remote_name)
  endif
endfunction

" Commands for remote operations
command! -nargs=? GBrowse call ghostgit#remote#Browse(<f-args>)
command! -nargs=? GFile call ghostgit#remote#BrowseFile(<f-args>)
command! GRemotes call ghostgit#remote#Show()