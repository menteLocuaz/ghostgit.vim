" ============================================================================
" ghostgit.vim - Core Git API
" ============================================================================

" Run a git command and return output
function! ghostgit#core#Run(args, ...) abort
  " Get the working directory
  let l:user_provided_cwd = (a:0 > 0)
  let l:cwd = get(a:000, 0, getcwd())

  " Fallback to RepoRoot if cwd is empty or invalid (only when not explicitly provided)
  if !l:user_provided_cwd && (empty(l:cwd) || !isdirectory(l:cwd))
    let l:cwd = ghostgit#core#RepoRoot()
  endif

  " Verify that the directory exists
  if empty(l:cwd) || !isdirectory(l:cwd)
    call ghostgit#util#Error('Directory does not exist: ' . l:cwd)
    return []
  endif

  " Verify that we have arguments to run
  if empty(a:args) || (type(a:args) == v:t_string && a:args =~# '^\s*$')
    call ghostgit#util#Error('Git command required')
    return []
  endif

  " Build git command using -C to avoid global cd side effects
  let l:cmd = ['git', '-C', l:cwd]
  if type(a:args) == v:t_list
    let l:cmd += a:args
  else
    call add(l:cmd, a:args)
  endif

  let l:output = systemlist(l:cmd)
  let l:exit = v:shell_error

  " Handling Git errors
  if l:exit != 0
    " For some commands, the exit code != 0 may be valid
    " For example, 'git rev-parse --verify HEAD' fails on empty repositories
    " But in most cases, we show an error (unless silent is requested)
    let l:opts = get(a:000, 1, {})
    let l:silent = type(l:opts) == v:t_dict ? get(l:opts, 'silent', 0) : 0
    
    if !l:silent
      call ghostgit#util#Error(join(l:output, "\n"))
    endif
    return []
  endif

  return l:output
endfunction

" Execute git command with smart output handling (Fugitive-style)
function! ghostgit#core#Execute(args) abort
  " If no arguments, open GStatus
  if empty(trim(a:args))
    call ghostgit#status#Open()
    return
  endif

  let l:arg_list = split(a:args)
  let l:cmd_name = get(l:arg_list, 0, '')
  let l:output = ghostgit#core#Run(l:arg_list)

  if empty(l:output) | return | endif

  " Decide how to display output
  " If it's more than 10 lines or a command that produces structured output
  if len(l:output) > 10 || l:cmd_name =~# '^\(diff\|show\|log\|blame\|status\)$'
    call ghostgit#util#OpenBuffer('output')
    
    " Set syntax based on command
    if l:cmd_name ==# 'diff' || l:cmd_name ==# 'show'
      setlocal filetype=diff
    elseif l:cmd_name ==# 'log'
      setlocal filetype=git
    elseif l:cmd_name ==# 'status'
      setlocal filetype=ghostgit_status
    endif

    call ghostgit#util#Render(l:output)
    nnoremap <silent><buffer> q :bd!<CR>
  else
    " For short output, just echo it
    for l:line in l:output
      call ghostgit#util#Info(l:line)
    endfor
  endif
endfunction

" Return root from current repo
function! ghostgit#core#RepoRoot(...) abort
  " Get current directory
  let l:cwd = get(a:000, 0, getcwd())

  " Verify cache first for better performance
  let l:entry = ghostgit#state#GetRepo(l:cwd)
  if !empty(l:entry) && !empty(get(l:entry, 'git_dir', ''))
    return l:entry.git_dir
  endif

  " Run the git command to get root access
  let l:result = ghostgit#core#Run(['rev-parse', '--show-toplevel'], l:cwd)

  " Check result
  if !empty(l:result) && !empty(l:result[0])
    let l:root = l:result[0]

    " Validate that the result is a valid directory
    if isdirectory(l:root)
      " Cache the repository root
      call ghostgit#state#SetRepo(l:root)
      let g:ghostgit_state.repos[l:root].git_dir = l:root
      return l:root
    else
      call ghostgit#util#Warn('Git root is not a valid directory: ' . l:root)
    endif
  endif

  return ''
endfunction

" Return current branch
function! ghostgit#core#CurrentBranch(...) abort
  " Get working directory
  let l:cwd = get(a:000, 0, getcwd())

  " Run command to get branch
  let l:result = ghostgit#core#Run(['rev-parse', '--abbrev-ref', 'HEAD'], l:cwd)

  " Process result
  if !empty(l:result) && !empty(l:result[0])
    " Handling special case of HEAD detached
    if l:result[0] == 'HEAD'
      " Get commit hash instead of HEAD
      let l:hash_result = ghostgit#core#Run(['rev-parse', '--short', 'HEAD'], l:cwd)
      if !empty(l:hash_result) && !empty(l:hash_result[0]) 
        return 'HEAD detached at ' . l:hash_result[0]
      endif
    endif
    return l:result[0]
  endif

  return ''
endfunction

" Check if the current directory is a git repository
function! ghostgit#core#IsRepo(...) abort
  " Get working directory
  let l:cwd = get(a:000, 0, getcwd())

  " Run the git command to check if it's a repository
  let l:output = ghostgit#core#Run(['rev-parse', '--git-dir'], l:cwd, {'silent': 1})
  return !empty(l:output)
endfunction

" Get list of branches
function! ghostgit#core#ListBranches(...) abort
  " Get working directory
  let l:cwd = get(a:000, 0, getcwd())

  " Get local branches
  let l:local_branches = ghostgit#core#Run(['branch', '--format', '%(refname:short)'], l:cwd)

  " Obtain remote branches
  let l:remote_branches = ghostgit#core#Run(['branch', '-r', '--format', '%(refname:short)'], l:cwd)

  " Combine results
  return l:local_branches + l:remote_branches
endfunction

" Get latest commit
function! ghostgit#core#LastCommit(...) abort 
  " Get working directory
  let l:cwd = get(a:000, 0, getcwd())

  " Get information about the last commit
  let l:hash = ghostgit#core#Run(['rev-parse', 'HEAD'], l:cwd)
  let l:subject = ghostgit#core#Run(['log', '-1', '--format=%s'], l:cwd)
  let l:author = ghostgit#core#Run(['log', '-1', '--format=%an'], l:cwd)
  let l:date = ghostgit#core#Run(['log', '-1', '--format=%ad', '--date=relative'], l:cwd)

  " Verify that we have all the data
  if empty(l:hash) || empty(l:subject) || empty(l:author) || empty(l:date)
    return {}
  endif

  return {
    \ 'hash': l:hash[0], 
    \ 'subject': l:subject[0], 
    \ 'author': l:author[0],
    \ 'date': l:date[0] 
    \ } 
endfunction
