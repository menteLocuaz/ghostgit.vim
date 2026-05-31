" ============================================================================
" ghostgit.vim - Core Git API
" ============================================================================

" Global variables for configurations
if !exists('g:ghostgit_core_timeout')
  let g:ghostgit_core_timeout = 30
endif

" Execute a Git command and return the output
function! ghostgit#core#Run(args, ...) abort
  " Obtener directorio de trabajo
  let l:user_provided_cwd = (a:0 > 0)
  let l:cwd = get(a:000, 0, getcwd())
  let l:opts = get(a:000, 1, {})

  " Verify that the directory exists
  if !empty(l:cwd) && !isdirectory(l:cwd)
    call ghostgit#util#Error('Directory does not exist: ' . l:cwd)
    return []
  endif

  " Fallback to RepoRoot if cwd is empty or invalid (only when not explicitly provided)
  if !l:user_provided_cwd && (empty(l:cwd) || !isdirectory(l:cwd))
    let l:cwd = ghostgit#core#RepoRoot()
  endif

  " Double-check that the directory exists
  if empty(l:cwd) || !isdirectory(l:cwd)
    call ghostgit#util#Error('Unable to determine Git repository root')
    return []
  endif

  " Verify that we have arguments to execute
  if empty(a:args)
    call ghostgit#util#Error('Git command required')
    return []
  endif

  " Convert args to a list if it's a string
  let l:cmd_args = type(a:args) == v:t_list ? a:args : [a:args]

  " Verify that the arguments are not empty.
  if empty(l:cmd_args) || (len(l:cmd_args) == 1 && empty(trim(l:cmd_args[0])))
    call ghostgit#util#Error('Git command required')
    return []
  endif

  " Build Git command using -C to avoid global side effects
  let l:cmd = ['git', '-C', l:cwd] + l:cmd_args

  " Run command with timeout if configured
  let l:output = []
  let l:exit = 0
  
  try
    if exists('*job_start') && g:ghostgit_core_timeout > 0
      " Use jobs for timeout in Vim 8+
      let l:output = ghostgit#core#RunWithTimeout(l:cmd, g:ghostgit_core_timeout)
    else
      " Normal execution
      let l:output = systemlist(l:cmd)
      let l:exit = v:shell_error
    endif
  catch
    call ghostgit#util#Error('Failed to execute Git command: ' . v:exception)
    return []
  endtry

  " Git error handling
  if l:exit != 0
    " For some commands, the exit code != 0 may be valid
    " For example, 'git rev-parse --verify HEAD' fails on empty repositories
    let l:silent = type(l:opts) == v:t_dict ? get(l:opts, 'silent', 0) : 0
    
    if !l:silent
      if !empty(l:output)
        call ghostgit#util#Error(join(l:output, "\n"))
      else
        call ghostgit#util#Error('Git command failed with exit code: ' . l:exit)
      endif
    endif
    return []
  endif

  return l:output
endfunction

" Execute command with timeout (Vim 8+)
function! ghostgit#core#RunWithTimeout(cmd, timeout) abort
  let l:job = job_start(a:cmd, {'close_cb': 'GhostGitJobClose'})
  let l:ch = job_getchannel(l:job)
  let l:output = []
  let l:start_time = reltime()
  
  " Wait until timeout or completion
  while job_status(l:job) == 'run' && reltimefloat(reltime(l:start_time)) < a:timeout
    if ch_status(l:ch) == 'buffered'
      let l:data = ch_read(l:ch, {'raw': 1})
      let l:lines = split(l:data, "\n", 1)
      let l:output += l:lines
    endif
    sleep 10m
  endwhile
  
  " If the job is still running, terminate it.
  if job_status(l:job) == 'run'
    call job_stop(l:job, 'kill')
    throw 'Command timed out after ' . a:timeout . ' seconds'
  endif
  
  return l:output
endfunction

" Callback for jobs
function! GhostGitJobClose(channel) abort
  " Callback necesario pero no usado
endfunction

" Execute Git command with intelligent output handling (Fugitive style)
function! ghostgit#core#Execute(args) abort
  " If there are no arguments, open GStatus
  if empty(trim(a:args))
    call ghostgit#status#Open()
    return
  endif

  let l:arg_list = split(a:args)
  let l:cmd_name = get(l:arg_list, 0, '')
  
  " Special commands that need different treatment
  if l:cmd_name ==# 'commit'
    " Open commit interface
    call call('ghostgit#commit#Open', l:arg_list[1:])
    return
  endif

  let l:output = ghostgit#core#Run(l:arg_list)

  if empty(l:output) 
    " Check if there was an error or if there is simply no exit.
    if v:shell_error == 0
      call ghostgit#util#Info('Command completed successfully (no output)')
    endif
    return 
  endif

  " Decide how to display the output
  " If it has more than 10 lines or is a command that produces structured output
  if len(l:output) > 10 || l:cmd_name =~# '^\(diff\|show\|log\|blame\|status\|stash\)$'
    " Open special buffer for long output
    call ghostgit#util#OpenBuffer('git://' . join(l:arg_list, '/'))
    
    " Establish command-based syntax
    if l:cmd_name ==# 'diff' || l:cmd_name ==# 'show'
      setlocal filetype=diff
    elseif l:cmd_name ==# 'log'
      setlocal filetype=git
    elseif l:cmd_name ==# 'status'
      setlocal filetype=gitcommit
    elseif l:cmd_name ==# 'stash'
      setlocal filetype=git
    else
      setlocal filetype=text
    endif

    " Render output
    call ghostgit#util#Render(l:output)
    
    " Configure mappings for navigation
    nnoremap <silent><buffer> q :bd!<CR>
    nnoremap <silent><buffer> <C-c> :bd!<CR>
    
    " Configure buffer options
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile
  else
    " For a short exit, simply show it.
    for l:line in l:output
      call ghostgit#util#Info(l:line)
    endfor
  endif
endfunction

" Return root of current repository
function! ghostgit#core#RepoRoot(...) abort
  " Get current directory
  let l:cwd = get(a:000, 0, getcwd())

  " Verify cache first for better performance
  let l:entry = ghostgit#state#GetRepo(l:cwd)
  if !empty(l:entry) && !empty(get(l:entry, 'git_dir', ''))
    return l:entry.git_dir
  endif

  " Verify that the directory exists
  if empty(l:cwd) || !isdirectory(l:cwd)
    return ''
  endif

  " Run a Git command to gain root access
  let l:result = ghostgit#core#Run(['rev-parse', '--show-toplevel'], l:cwd, {'silent': 1})

  " Check result
  if !empty(l:result) && !empty(l:result[0])
    let l:root = simplify(fnamemodify(l:result[0], ':p'))

    " Validate that the result is a valid directory
    if isdirectory(l:root)
      " Caching the repository root
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
  
  " Verify that we are in a repository
  if empty(ghostgit#core#RepoRoot(l:cwd))
    return ''
  endif

  " Run command to obtain branch
  let l:result = ghostgit#core#Run(['rev-parse', '--abbrev-ref', 'HEAD'], l:cwd, {'silent': 1})

  " Process result
  if !empty(l:result) && !empty(l:result[0])
    let l:branch = l:result[0]
    
    " Handle special case of detached HEAD
    if l:branch == 'HEAD'
      " Get the commit hash instead of HEAD
      let l:hash_result = ghostgit#core#Run(['rev-parse', '--short', 'HEAD'], l:cwd, {'silent': 1})
      if !empty(l:hash_result) && !empty(l:hash_result[0]) 
        return 'HEAD detached at ' . l:hash_result[0]
      endif
      return 'HEAD detached'
    endif
    
    return l:branch
  endif

  return ''
endfunction

" Check if the current directory is a Git repository
function! ghostgit#core#IsRepo(...) abort
  " Get working directory
  let l:cwd = get(a:000, 0, getcwd())

  " Verify that the directory exists
  if empty(l:cwd) || !isdirectory(l:cwd)
    return 0
  endif

  " Run command to check if it is a repository
  let l:output = ghostgit#core#Run(['rev-parse', '--git-dir'], l:cwd, {'silent': 1})
  return !empty(l:output)
endfunction

" Get list of branches
function! ghostgit#core#ListBranches(...) abort
  " Get working directory
  let l:cwd = get(a:000, 0, getcwd())
  
  " Verify that we are in a repository
  if empty(ghostgit#core#RepoRoot(l:cwd))
    return []
  endif

  " Get local branches
  let l:local_branches = ghostgit#core#Run(['branch', '--format', '%(refname:short)'], l:cwd, {'silent': 1})

  " Get remote branches
  let l:remote_branches = ghostgit#core#Run(['branch', '-r', '--format', '%(refname:short)'], l:cwd, {'silent': 1})

  " Combine results and remove duplicates
  let l:all_branches = l:local_branches + l:remote_branches
  
  " Delete empty entries
  call filter(l:all_branches, '!empty(v:val)')
  
  return l:all_branches
endfunction

" Get latest commit
function! ghostgit#core#LastCommit(...) abort 
  " Get working directory
  let l:cwd = get(a:000, 0, getcwd())
  
  " Verify that we are in a repository
  if empty(ghostgit#core#RepoRoot(l:cwd))
    return {}
  endif

  try
    " Get information about the last commit in a single call
    let l:format_string = "%H%n%s%n%an%n%ad"
    let l:info = ghostgit#core#Run(['log', '-1', '--format=' . l:format_string, '--date=relative'], l:cwd, {'silent': 1})
    
    " Verify that we have all the data
    if len(l:info) >= 4
      return {
        \ 'hash': l:info[0], 
        \ 'subject': l:info[1], 
        \ 'author': l:info[2],
        \ 'date': l:info[3] 
        \ }
    endif
  catch
    " In case of error, return empty dictionary
    call ghostgit#util#Warn('Failed to retrieve last commit info: ' . v:exception)
  endtry

  return {}
endfunction

" Get repository status
function! ghostgit#core#Status(...) abort
  " Get working directory
  let l:cwd = get(a:000, 0, getcwd())
  
  " Verify that we are in a repository
  if empty(ghostgit#core#RepoRoot(l:cwd))
    return []
  endif

  " Get repository status
  return ghostgit#core#Run(['status', '--porcelain', '-b'], l:cwd, {'silent': 1})
endfunction

" Get list of modified files
function! ghostgit#core#ModifiedFiles(...) abort
  " Get list of modified files
  let l:cwd = get(a:000, 0, getcwd())
  
  " Verify that we are in a repository
  if empty(ghostgit#core#RepoRoot(l:cwd))
    return []
  endif

  " Get modified files
  let l:files = []
  for l:line in ghostgit#core#Run(['status', '--porcelain'], l:cwd, {'silent': 1})
    if len(l:line) > 3
      call add(l:files, l:line[3:])
    endif
  endfor

  return l:files
endfunction