" ============================================================================
" ghostgit.vim - Core Git API
" ============================================================================

" Global variables for configurations
if !exists('g:ghostgit_core_timeout')
  let g:ghostgit_core_timeout = 30
endif

" Execute a Git command and return the output (sync) or start a job (async)
function! ghostgit#core#Run(args, ...) abort
  let l:cwd = get(a:000, 0, '')
  let l:opts = get(a:000, 1, {})
  let l:user_provided_cwd = !empty(l:cwd)

  " Determine working directory
  if !l:user_provided_cwd
    let l:cwd = ghostgit#core#RepoRoot()
  endif

  if empty(l:cwd) || !isdirectory(l:cwd)
    if !get(l:opts, 'silent', 0)
      call ghostgit#util#Error('Unable to determine Git repository root or directory does not exist')
    endif
    return []
  endif

  " Convert args to a list if it's a string
  let l:cmd_args = type(a:args) == v:t_list ? a:args : split(a:args)
  if empty(l:cmd_args)
    return []
  endif

  " Build Git command
  let l:cmd = ['git', '-C', l:cwd] + l:cmd_args

  " Support async execution if a callback is provided in opts
  if has_key(l:opts, 'on_success') || has_key(l:opts, 'on_exit')
    return ghostgit#job#Run(l:cmd, l:opts)
  endif

  " Run command with timeout handling
  let l:timeout = get(l:opts, 'timeout', g:ghostgit_core_timeout)
  let l:output = []
  let l:exit = 0

  try
    if l:timeout > 0 && ghostgit#job#IsAvailable()
      if has('nvim')
        let [l:output, l:exit] = s:NvimRunWithTimeout(l:cmd, l:timeout)
      else
        let l:output = ghostgit#core#RunWithTimeout(l:cmd, l:timeout)
        let l:exit = 0
      endif
    else
      let l:output = systemlist(l:cmd)
      let l:exit = v:shell_error
    endif
  catch
    if !get(l:opts, 'silent', 0)
      call ghostgit#util#Error('Git command failed: ' . v:exception)
    endif
    return []
  endtry

  " Error handling
  if l:exit != 0 && !get(l:opts, 'silent', 0)
    if !empty(l:output)
      call ghostgit#util#Error(join(l:output, "\n"))
    else
      call ghostgit#util#Error('Git command failed with exit code: ' . l:exit)
    endif
    return []
  endif

  return l:output
endfunction

" Execute command with timeout in Neovim
function! s:NvimRunWithTimeout(cmd, timeout) abort
  let l:stdout = []
  let l:job_id = jobstart(a:cmd, {
        \ 'on_stdout': {ch, data -> extend(l:stdout, data)},
        \ 'stdout_buffered': 1
        \ })

  if l:job_id <= 0
    throw 'Failed to start Neovim job'
  endif

  let l:res = jobwait([l:job_id], a:timeout * 1000)
  if l:res[0] == -1
    call jobstop(l:job_id)
    throw 'Command timed out after ' . a:timeout . ' seconds'
  elseif l:res[0] == -2
    throw 'Command interrupted'
  endif

  if !empty(l:stdout) && empty(l:stdout[-1])
    call remove(l:stdout, -1)
  endif
  return [l:stdout, l:res[0]]
endfunction

" Execute command with timeout (Vim 8+)
function! ghostgit#core#RunWithTimeout(cmd, timeout) abort
  let l:job = job_start(a:cmd, {'close_cb': 'GhostGitJobClose'})
  let l:ch = job_getchannel(l:job)
  let l:output = []
  let l:start_time = reltime()

  " Wait until timeout or completion
  " Performance: sleep allows UI redrawing but blocks script execution.
  while job_status(l:job) == 'run' && reltimefloat(reltime(l:start_time)) < a:timeout
    if ch_status(l:ch) == 'buffered'
      let l:data = ch_read(l:ch, {'raw': 1})
      let l:lines = split(l:data, "\n", 1)
      let l:output += l:lines
    endif
    sleep 5m
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
  let l:force_paginate = 0

  " Check for pagination flags
  if l:cmd_name ==# '-p' || l:cmd_name ==# '--paginate'
    let l:force_paginate = 1
    call remove(l:arg_list, 0)
    let l:cmd_name = get(l:arg_list, 0, '')
  endif

  " Special commands that need different treatment
  if l:cmd_name ==# 'commit'
    " Open commit interface
    call call('ghostgit#commit#Open', l:arg_list[1:])
    return
  elseif l:cmd_name ==# 'blame'
    " Use dedicated blame module
    if len(l:arg_list) > 1
      call ghostgit#blame#Open(l:arg_list[1])
    else
      call ghostgit#blame#Open()
    endif
    return
  elseif l:cmd_name ==# 'mergetool' || l:cmd_name ==# 'difftool'
    " Run sync and load into quickfix for these tools
    let l:output = ghostgit#core#Run(l:arg_list)
    if !empty(l:output)
      cexpr l:output
      copen
    endif
    return
  endif

  " Use job queue for Execute to keep UI responsive
  call ghostgit#job#Schedule('execute', ['git'] + l:arg_list, {
        \ 'on_success': {lines -> s:OnExecuteResult(l:cmd_name, l:arg_list, lines, l:force_paginate)},
        \ 'on_failure': {err -> ghostgit#util#Error('Git command failed: ' . join(err, "\n"))}
        \ })
endfunction

" Callback for Execute result
function! s:OnExecuteResult(cmd_name, arg_list, output, force_paginate) abort
  if empty(a:output)
    " Avoid 'Press ENTER' for quiet commands by using simple echo if possible
    echo '[ghostgit] Command completed successfully (no output)'
    return
  endif

  " Decide how to display the output
  " If it has more than 10 lines or is a command that produces structured output
  if a:force_paginate || len(a:output) > 10 || a:cmd_name =~# '^\(diff\|show\|log\|blame\|status\|stash\)$'
    " Determine filetype based on command
    let l:ft = 'text'
    if a:cmd_name ==# 'diff' || a:cmd_name ==# 'show'
      let l:ft = 'diff'
    elseif a:cmd_name ==# 'log' || a:cmd_name ==# 'stash'
      let l:ft = 'git'
    elseif a:cmd_name ==# 'status'
      let l:ft = 'gitcommit'
    endif

    " Open special buffer for long output
    call ghostgit#util#OpenBuffer('git://' . join(a:arg_list, '/'), {'filetype': l:ft})

    " Render output
    call ghostgit#util#Render(a:output)
  else
    " For a short exit, simply show it.
    for l:line in a:output
      if !empty(l:line)
        call ghostgit#util#Info(l:line)
      endif
    endfor
  endif
endfunction

" Return root of current repository
function! ghostgit#core#RepoRoot(...) abort
  let l:cwd = get(a:000, 0, '')

  " If no path provided, prioritize current buffer's directory over getcwd()
  if empty(l:cwd)
    let l:buf_path = expand('%:p:h')
    if !empty(l:buf_path) && isdirectory(l:buf_path)
      let l:cwd = l:buf_path
    else
      let l:cwd = getcwd()
    endif
  endif

  " Buffer-local cache check
  if a:0 == 0 && exists('b:ghostgit_repo_root') && !empty(b:ghostgit_repo_root)
    if exists('b:ghostgit_repo_cwd') && b:ghostgit_repo_cwd ==# l:cwd
      return b:ghostgit_repo_root
    endif
  endif

  " Global cache check
  let l:repos = exists('g:ghostgit_state') ? get(g:ghostgit_state, 'repos', {}) : {}
  let l:entry = get(l:repos, l:cwd, {})
  if !empty(get(l:entry, 'git_dir', '')) && isdirectory(l:entry.git_dir)
    if a:0 == 0
      let b:ghostgit_repo_root = l:entry.git_dir
      let b:ghostgit_repo_cwd = l:cwd
    endif
    return l:entry.git_dir
  endif

  " Run git rev-parse
  let l:result = ghostgit#core#Run(['rev-parse', '--show-toplevel'], l:cwd, {'silent': 1})
  if !empty(l:result) && !empty(l:result[0])
    let l:root = simplify(fnamemodify(l:result[0], ':p'))
    if isdirectory(l:root)
      if exists('g:ghostgit_state')
        call ghostgit#state#SetRepo(l:root, {'git_dir': l:root})
        let g:ghostgit_state.repos[l:cwd] = g:ghostgit_state.repos[l:root]
      endif

      if a:0 == 0
        let b:ghostgit_repo_root = l:root
        let b:ghostgit_repo_cwd = l:cwd
      endif
      return l:root
    endif
  endif

  return ''
endfunction

" Return current branch
function! ghostgit#core#CurrentBranch(...) abort
  let l:cwd = get(a:000, 0, getcwd())
  let l:root = ghostgit#core#RepoRoot(l:cwd)
  if empty(l:root) | return '' | endif

  " Skip cache when called with an explicit cwd — the caller cares about
  " accuracy, not speed (e.g., after a branch switch in a test or callback).
  if a:0 == 0
    let l:repo = ghostgit#state#GetRepo(l:root)
    if !empty(get(l:repo, 'branch', '')) && (localtime() - get(l:repo, 'last_refresh', 0) < 5)
      return l:repo.branch
    endif
  endif

  let l:result = ghostgit#core#Run(['rev-parse', '--abbrev-ref', 'HEAD'], l:cwd, {'silent': 1})
  if !empty(l:result) && !empty(l:result[0])
    let l:branch = l:result[0]
    if l:branch == 'HEAD'
      let l:hash_result = ghostgit#core#Run(['rev-parse', '--short', 'HEAD'], l:cwd, {'silent': 1})
      let l:branch = 'HEAD detached at ' . get(l:hash_result, 0, 'unknown')
    endif

    " Update cache
    if exists('g:ghostgit_state')
      call ghostgit#state#SetRepo(l:root, {'branch': l:branch, 'last_refresh': localtime()})
    endif
    return l:branch
  endif

  return ''
endfunction

" Check if the current directory is a Git repository
function! ghostgit#core#IsRepo(...) abort
  let l:cwd = get(a:000, 0, getcwd())

  if empty(l:cwd) || !isdirectory(l:cwd)
    return 0
  endif

  let l:output = ghostgit#core#Run(['rev-parse', '--git-dir'], l:cwd, {'silent': 1})
  return !empty(l:output) && l:output[0] !~# '^fatal:'
endfunction

" Get list of branches
function! ghostgit#core#ListBranches(...) abort
  let l:cwd = get(a:000, 0, getcwd())

  if empty(ghostgit#core#RepoRoot(l:cwd))
    return []
  endif

  let l:local_branches = ghostgit#core#Run(['branch', '--format', '%(refname:short)'], l:cwd, {'silent': 1})

  let l:remote_branches = ghostgit#core#Run(['branch', '-r', '--format', '%(refname:short)'], l:cwd, {'silent': 1})

  let l:all_branches = l:local_branches + l:remote_branches

  call filter(l:all_branches, '!empty(v:val)')

  return l:all_branches
endfunction

" Get latest commit
function! ghostgit#core#LastCommit(...) abort
  let l:cwd = get(a:000, 0, getcwd())

  if empty(ghostgit#core#RepoRoot(l:cwd))
    return {}
  endif

  try
    let l:format_string = "%H%n%s%n%an%n%ad"
    let l:info = ghostgit#core#Run(['log', '-1', '--format=' . l:format_string, '--date=relative'], l:cwd, {'silent': 1})

    if len(l:info) >= 4
      return {
        \ 'hash': l:info[0],
        \ 'subject': l:info[1],
        \ 'author': l:info[2],
        \ 'date': l:info[3]
        \ }
    endif
  catch
    call ghostgit#util#Warn('Failed to retrieve last commit info: ' . v:exception)
  endtry

  return {}
endfunction

" Get repository status
function! ghostgit#core#Status(...) abort
  let l:cwd = get(a:000, 0, getcwd())

  if empty(ghostgit#core#RepoRoot(l:cwd))
    return []
  endif

  return ghostgit#core#Run(['status', '--porcelain', '-b'], l:cwd, {'silent': 1})
endfunction

" Get list of modified files
function! ghostgit#core#ModifiedFiles(...) abort
  let l:cwd = get(a:000, 0, getcwd())

  if empty(ghostgit#core#RepoRoot(l:cwd))
    return []
  endif

  let l:files = []
  for l:line in ghostgit#core#Run(['status', '--porcelain'], l:cwd, {'silent': 1})
    if len(l:line) > 3
      call add(l:files, l:line[3:])
    endif
  endfor

  return l:files
endfunction
