<<<<<<< HEAD
" ============================================================================
" ghostgit.vim - Cross-compatible Job Wrapper
" ============================================================================

" Detect Vim vs Neovim
function! ghostgit#job#IsNvim() abort
  return has('nvim')
endfunction

" Unified job start
function! ghostgit#job#Start(cmd, on_stdout, on_exit, ...) abort
  " Validar argumentos
  if empty(a:cmd)
    throw "ghostgit#job#Start: cmd cannot be empty"
  endif

  " Get the working directory, using getcwd() as the default value
  let l:cwd = get(a:000, 0, getcwd())
  
  " Verify that the directory exists
  if !isdirectory(l:cwd)
    throw "ghostgit#job#Start: cwd does not exist: " . l:cwd
  endif

  try
    if ghostgit#job#IsNvim()
      return s:JobStartNvim(a:cmd, a:on_stdout, a:on_exit, l:cwd)
    elseif exists('*job_start')
      return s:JobStartVim8(a:cmd, a:on_stdout, a:on_exit, l:cwd)
    else
      " Run fallback only if there is no job support
      return s:JobFallback(a:cmd, a:on_stdout, a:on_exit, l:cwd)
    endif
  catch
    " Log errors if a logging system exists
    if exists('*ghostgit#util#Error')
      call ghostgit#util#Error("Job start failed: " . v:exception)
    endif
    throw v:exception
  endtry
endfunction

" Neovim job handler
function! s:JobStartNvim(cmd, on_stdout, on_exit, cwd) abort
  " validate callbacks
  if type(a:on_stdout) != v:t_string || type(a:on_exit) != v:t_string
    throw "ghostgit#JobStartNvim: callbacks must be function names (strings)"
  endif

  " Prepare options for Neovim
  let l:opts = {
        \ 'on_stdout': function(a:on_stdout),
        \ 'on_stderr': function(a:on_stdout),  " Handle stderr too
        \ 'on_exit': function(a:on_exit),
        \ 'cwd': a:cwd
        \ }
  
  " Start a job in Neovim
  let l:job = jobstart(a:cmd, l:opts)
  
  " Verify if the job started correctly
  if l:job == -1
    throw "ghostgit#job#StartNvim: Failed to start job"
  endif
  
  return l:job
endfunction

" Vim8 job handler
function! s:JobStartVim8(cmd, on_stdout, on_exit, cwd) abort
  " Validar callbacks
  if type(a:on_stdout) != v:t_string || type(a:on_exit) != v:t_string
    throw "ghostgit#JobStartVim8: callbacks must be function names (strings)"
  endif

  " Prepare options for Vim8
  let l:opts = {
        \ 'out_cb': function(a:on_stdout),
        \ 'err_cb': function(a:on_stdout),  " Handle stderr too
        \ 'exit_cb': function(a:on_exit),
        \ 'cwd': a:cwd
        \ }
  
  " Start job in Vim8
  let l:job = job_start(a:cmd, l:opts)
  
  " Verify if the job started correctly
  if job_status(l:job) != "run"
    " Limpiar job si falló
    if job_status(l:job) == "run"
      call job_stop(l:job)
    endif
    throw "ghostgit#job#StartVim8: Failed to start job"
  endif
  
  return l:job
endfunction

" Fallback synchronous
function! s:JobFallback(cmd, on_stdout, on_exit, cwd) abort
  " Validar callbacks
  if type(a:on_stdout) != v:t_string || type(a:on_exit) != v:t_string
    throw "ghostgit#JobFallback: callbacks must be function names (strings)"
  endif

  " Save the current directory and change to the specified one.
  let l:old_cwd = getcwd()
  execute "lcd " . fnameescape(a:cwd)
  
  try
    " Execute command and capture output
    let l:output = systemlist(a:cmd)
    let l:exit_code = v:shell_error
    
    " Call outbound callback with each line
    if !empty(l:output)
      for l:line in l:output
        call call(function(a:on_stdout), [[l:line]])
      endfor
    endif
    
    " Call out callback with an empty line to indicate end
    call call(function(a:on_stdout), [['']])
    
    " Call completion callback
    call call(function(a:on_exit), [l:exit_code])
    
    return { 'output': l:output, 'exit_code': l:exit_code }
  catch
    " Restore directory even if there are errors
    execute "lcd " . fnameescape(l:old_cwd)
    throw "ghostgit#JobFallback: " . v:exception
  finally
    " Always restore the original directory
    if getcwd() != l:old_cwd
      execute "lcd " . fnameescape(l:old_cwd)
    endif
  endtry
endfunction

" Function to stop a job
function! ghostgit#job#Stop(job_id) abort
  if ghostgit#job#IsNvim()
    " In Neovim, job_id is a number
    call jobstop(a:job_id)
  elseif exists('*job_stop')
    " En Vim8, job_id es un job object
    call job_stop(a:job_id)
  else
    " In fallback mode, there are no jobs to stop.
    call ghostgit#util#Warn("Job stopping not supported in fallback mode")
  endif
endfunction

" Function to get the status of a job
function! ghostgit#job#Status(job_id) abort
  if ghostgit#job#IsNvim()
    " In Neovim, we need to verify in another way
    " For simplicity, we assume that if it exists, it is running.
    return "unknown"
  elseif exists('*job_status')
    " In Vim8, we use job_status
    return job_status(a:job_id)
  else
    " In fallback mode, there are no active jobs.
    return "none"
  endif
endfunction
=======
" ============================================================================
" ghostgit.vim - Async Job Runner
" ============================================================================
" Abstracts jobstart() (Neovim), job_start() (Vim8), and systemlist()
" fallback behind a single interface.

let s:job_id = 0
let s:jobs = {}

" Returns 1 if true async jobs are available, 0 if using sync fallback
function! ghostgit#job#IsAvailable() abort
  if has('nvim')
    return exists('*jobstart') ? 1 : 0
  elseif has('job')
    return 1
  endif
  return 0
endfunction

" Run a command
" a:cmd  - String or List of command args
" a:opts - Dict with optional keys:
"   cwd       - working directory (default getcwd())
"   on_stdout - Funcref(channel, lines)  called with list of stdout lines
"   on_stderr - Funcref(channel, lines)  called with list of stderr lines
"   on_exit   - Funcref(job, exit_code) called on completion
" Returns numeric job id (>= 0) if async, -1 if sync fallback was used
function! ghostgit#job#Run(cmd, opts) abort
  let l:cmd = type(a:cmd) == v:t_list ? copy(a:cmd) : [a:cmd]
  let l:opts = a:opts

  if has('nvim') && exists('*jobstart')
    return s:NvimRun(l:cmd, l:opts)
  elseif has('job')
    return s:Vim8Run(l:cmd, l:opts)
  else
    return s:SyncRun(l:cmd, l:opts)
  endif
endfunction

" Wait for a job to finish (no-op for sync fallback)
function! ghostgit#job#Wait(job_id) abort
  if a:job_id < 0 | return | endif

  if has('nvim') && exists('*jobwait')
    call jobwait([a:job_id])
  elseif has('job') && exists('*job_wait') && has_key(s:jobs, a:job_id)
    call job_wait(s:jobs[a:job_id].job, 30000)
  elseif has('job') && exists('*job_status') && has_key(s:jobs, a:job_id)
    let l:job = s:jobs[a:job_id].job
    let l:waited = 0
    while job_status(l:job) ==# 'run' && l:waited < 30000
      sleep 10m
      let l:waited += 10
    endwhile
  endif
endfunction

" Stop a running job (no-op for sync fallback)
function! ghostgit#job#Stop(job_id) abort
  if a:job_id < 0 | return | endif

  if has('nvim') && exists('*jobstop')
    call jobstop([a:job_id])
  elseif has('job') && has_key(s:jobs, a:job_id)
    let l:job = s:jobs[a:job_id].job
    call job_stop(l:job)
  endif
endfunction

" Clean up stored state for a finished/stopped job
function! s:Cleanup(job_id) abort
  if has_key(s:jobs, a:job_id)
    unlet s:jobs[a:job_id]
  endif
endfunction

" ============================================================================
" Neovim: jobstart()
" ============================================================================
function! s:NvimRun(cmd, opts) abort
  let s:job_id += 1
  let l:id = s:job_id
  let l:cwd = get(a:opts, 'cwd', getcwd())

  let l:job_opts = {'cwd': l:cwd}

  if has_key(a:opts, 'on_stdout')
    let l:Cb = a:opts.on_stdout
    let l:job_opts.on_stdout = {ch, data -> l:Cb(ch, data)}
  endif

  if has_key(a:opts, 'on_stderr')
    let l:Cb = a:opts.on_stderr
    let l:job_opts.on_stderr = {ch, data -> l:Cb(ch, data)}
  endif

  if has_key(a:opts, 'on_exit')
    let l:Cb = a:opts.on_exit
    let l:job_opts.on_exit = {job, code, event -> l:Cb(job, code)}
  endif

  let l:raw_id = jobstart(a:cmd, l:job_opts)
  let s:jobs[l:id] = {'raw': l:raw_id}
  return l:id
endfunction

" ============================================================================
" Vim8: job_start()
" ============================================================================
function! s:Vim8Run(cmd, opts) abort
  let s:job_id += 1
  let l:id = s:job_id
  let l:cwd = get(a:opts, 'cwd', getcwd())

  let l:job_opts = {'cwd': l:cwd}

  if has_key(a:opts, 'on_stdout')
    let l:Cb = a:opts.on_stdout
    let l:job_opts.out_cb = {ch, msg -> l:Cb(ch, [msg])}
  endif

  if has_key(a:opts, 'on_stderr')
    let l:Cb = a:opts.on_stderr
    let l:job_opts.err_cb = {ch, msg -> l:Cb(ch, [msg])}
  endif

  if has_key(a:opts, 'on_exit')
    let l:Cb = a:opts.on_exit
    let l:job_opts.exit_cb = {job, code -> l:Cb(job, code)}
  endif

  let l:job = job_start(a:cmd, l:job_opts)
  let s:jobs[l:id] = {'job': l:job}
  return l:id
endfunction

" ============================================================================
" Fallback: systemlist() synchronous
" ============================================================================
function! s:SyncRun(cmd, opts) abort
  let l:cwd = get(a:opts, 'cwd', getcwd())
  let l:cmd = a:cmd

  " If it's a git command, we can use -C to avoid cd
  if type(l:cmd) == v:t_list && !empty(l:cmd) && l:cmd[0] ==# 'git'
    let l:cmd = ['git', '-C', l:cwd] + l:cmd[1:]
  endif

  let l:output = systemlist(l:cmd)
  let l:exit_code = v:shell_error

  let l:on_stdout = get(a:opts, 'on_stdout', v:null)
  let l:on_exit   = get(a:opts, 'on_exit', v:null)

  if l:on_stdout != v:null
    call l:on_stdout(0, l:output)
  endif

  if l:on_exit != v:null
    call l:on_exit(-1, l:exit_code)
  endif

  return -1
endfunction
>>>>>>> 26e876c (feat(log): implement :GLog with parser, renderer, and buffer lifecycle)
