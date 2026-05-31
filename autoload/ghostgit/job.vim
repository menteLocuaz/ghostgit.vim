" ============================================================================
" ghostgit.vim - Async Job Runner
" ============================================================================
" Abstracts jobstart() (Neovim), job_start() (Vim8), and systemlist()
" fallback behind a single interface.
"
" Extended with queue, debouncing, cancellation, and buffer-lifetime
" awareness (see Schedule, Debounce, Cancel, CancelBuffer).

let s:job_id = 0
let s:jobs = {}

" Queue system
let s:queue = []
let s:running = 0
let s:max_concurrent = 3

" Named jobs: name -> {id, run_id, bufnr}
let s:named_jobs = {}

" Debounce timers: name -> timer_id
let s:debounce_timers = {}

" Statistics
let s:stats = {'completed': 0, 'failed': 0, 'cancelled': 0}

" ============================================================================
" Public API — high-level
" ============================================================================

" Schedule a named job in the queue.  If a job with the same name already
" exists (queued or running) it is cancelled first.
"
" opts:
"   bufnr       - buffer to check liveness on completion
"   on_success  - Funcref(lines) called on exit code 0
"   on_failure  - Funcref(lines) called on non-zero exit
"   on_exit     - Funcref(name, exit_code) always called
"   cwd         - working directory
"   priority    - 1 (high), 0 (normal, default), -1 (low)
"
" Returns job id (> 0) or -1 if sync fallback was used.
function! ghostgit#job#Schedule(name, cmd, opts) abort
  if empty(a:cmd)
    throw 'ghostgit: Command cannot be empty'
  endif

  " Cancel any existing job with this name
  call ghostgit#job#Cancel(a:name)

  let s:job_id += 1
  let l:id = s:job_id

  let l:entry = {
        \ 'id': l:id,
        \ 'name': a:name,
        \ 'cmd': type(a:cmd) == v:t_list ? copy(a:cmd) : split(a:cmd),
        \ 'opts': a:opts,
        \ 'bufnr': get(a:opts, 'bufnr', 0),
        \ 'priority': get(a:opts, 'priority', 0)
        \ }

  let s:named_jobs[a:name] = {'id': l:id, 'bufnr': l:entry.bufnr}
  call s:Enqueue(l:entry)
  call s:ProcessQueue()

  return l:id
endfunction

" Debounce: cancel any pending job with the same name, then schedule
" after 'delay' ms of inactivity.  When g:ghostgit_async_disable is set
" or timer_start is unavailable the call is forwarded immediately.
function! ghostgit#job#Debounce(name, delay, cmd, opts) abort
  call ghostgit#job#Cancel(a:name)

  if get(g:, 'ghostgit_async_disable', 0) || !exists('*timer_start')
    return ghostgit#job#Schedule(a:name, a:cmd, a:opts)
  endif

  let s:debounce_timers[a:name] =
        \ timer_start(a:delay, {-> s:ExecuteDebounced(a:name, a:cmd, a:opts)})
  return 0
endfunction

" Cancel a named job.  Stops a running job and removes queued / debounced
" entries.  Returns 1 if something was cancelled, 0 otherwise.
function! ghostgit#job#Cancel(name) abort
  " Stop debounce timer
  if has_key(s:debounce_timers, a:name)
    try
      call timer_stop(s:debounce_timers[a:name])
    catch
    endtry
    unlet s:debounce_timers[a:name]
  endif

  " Remove from queue
  let l:found = 0
  let l:i = 0
  while l:i < len(s:queue)
    if s:queue[l:i].name ==# a:name
      call remove(s:queue, l:i)
      let l:found = 1
      break
    endif
    let l:i += 1
  endwhile

  " Stop running job
  if has_key(s:named_jobs, a:name)
    let l:info = s:named_jobs[a:name]
    if has_key(l:info, 'run_id') && l:info.run_id >= 0
      call ghostgit#job#Stop(l:info.run_id)
    endif
    unlet s:named_jobs[a:name]
    let l:found = 1
  endif

  if l:found
    let s:stats.cancelled += 1
  endif
  return l:found
endfunction

" Cancel all jobs associated with a buffer number.
function! ghostgit#job#CancelBuffer(bufnr) abort
  for [l:name, l:info] in items(s:named_jobs)
    if l:info.bufnr == a:bufnr
      call ghostgit#job#Cancel(l:name)
    endif
  endfor

  let l:i = 0
  while l:i < len(s:queue)
    if s:queue[l:i].bufnr == a:bufnr
      call remove(s:queue, l:i)
      let s:stats.cancelled += 1
    else
      let l:i += 1
    endif
  endwhile
endfunction

" Return the number of jobs currently queued + running.
function! ghostgit#job#PendingCount() abort
  return len(s:queue) + s:running
endfunction

" Return a copy of the performance stats dict.
function! ghostgit#job#Stats() abort
  return copy(s:stats)
endfunction

" ============================================================================
" Public API — low-level runners (unchanged contract)
" ============================================================================

" Check if true async jobs are available
function! ghostgit#job#IsAvailable() abort
  if get(g:, 'ghostgit_async_disable', 0)
    return 0
  endif
  if has('nvim')
    return exists('*jobstart') ? 1 : 0
  elseif has('job')
    return 1
  endif
  return 0
endfunction

" Run a command asynchronously or synchronously as fallback.
function! ghostgit#job#Run(cmd, opts) abort
  if empty(a:cmd)
    throw 'ghostgit: Command cannot be empty'
  endif

  let l:cmd = type(a:cmd) == v:t_list ? copy(a:cmd) : split(a:cmd)

  if get(g:, 'ghostgit_async_disable', 0)
    return s:SyncRun(l:cmd, a:opts)
  elseif has('nvim') && exists('*jobstart')
    return s:NvimRun(l:cmd, a:opts)
  elseif has('job')
    return s:Vim8Run(l:cmd, a:opts)
  else
    return s:SyncRun(l:cmd, a:opts)
  endif
endfunction

" Wait for a job to finish (no-op for sync fallback)
function! ghostgit#job#Wait(job_id) abort
  if a:job_id < 0 | return | endif
  if !has_key(s:jobs, a:job_id) | return | endif

  try
    if has('nvim') && exists('*jobwait') && has_key(s:jobs[a:job_id], 'raw')
      call jobwait([s:jobs[a:job_id].raw])
    elseif has('job') && exists('*job_wait') && has_key(s:jobs[a:job_id], 'job')
      call job_wait(s:jobs[a:job_id].job, 30000)
    elseif has('job') && exists('*job_status') && has_key(s:jobs[a:job_id], 'job')
      let l:job = s:jobs[a:job_id].job
      let l:waited = 0
      while job_status(l:job) ==# 'run' && l:waited < 30000
        sleep 10m
        let l:waited += 10
      endwhile
    endif
  catch
  endtry
endfunction

" Stop a running job (no-op for sync fallback)
function! ghostgit#job#Stop(job_id) abort
  if a:job_id < 0 | return | endif

  try
    if has('nvim') && exists('*jobstop') && has_key(s:jobs, a:job_id)
      call jobstop(s:jobs[a:job_id].raw)
    elseif has('job') && has_key(s:jobs, a:job_id)
      let l:job = s:jobs[a:job_id].job
      call job_stop(l:job)
    endif
  catch
  endtry
endfunction

" ============================================================================
" Queue internals
" ============================================================================

" Insert entry into queue sorted by priority (descending).
function! s:Enqueue(entry) abort
  let l:priority = get(a:entry, 'priority', 0)
  let l:inserted = 0
  for l:i in range(len(s:queue))
    if get(s:queue[l:i], 'priority', 0) < l:priority
      call insert(s:queue, a:entry, l:i)
      let l:inserted = 1
      break
    endif
  endfor
  if !l:inserted
    call add(s:queue, a:entry)
  endif
endfunction

" Factory: stdout accumulator callback (captures list ref via a:)
function! s:MakeStdoutCb(stdout) abort
  return {ch, data -> extend(a:stdout, data)}
endfunction

" Factory: stderr accumulator callback
function! s:MakeStderrCb(stderr) abort
  return {ch, data -> extend(a:stderr, data)}
endfunction

" Factory: exit handler that delegates to s:HandleExit.
" Uses a: arguments so it works in all Vim/Neovim lambda versions.
function! s:MakeExitCb(name, bufnr, stdout, stderr, on_success, on_failure, on_exit) abort
  return {job, code -> s:HandleExit(a:name, a:bufnr, a:stdout, a:stderr, code, a:on_success, a:on_failure, a:on_exit)}
endfunction

" Process next item in the queue if concurrency allows.
function! s:ProcessQueue() abort
  if s:running >= s:max_concurrent || empty(s:queue)
    return
  endif

  let l:entry = remove(s:queue, 0)
  let s:running += 1

  let l:name   = l:entry.name
  let l:cmd    = l:entry.cmd
  let l:opts   = l:entry.opts
  let l:bufnr  = l:entry.bufnr
  let l:cwd    = get(l:opts, 'cwd', getcwd())

  " Accumulate stdout / stderr
  let l:stdout = []
  let l:stderr = []

  let l:run_opts = {'cwd': l:cwd}
  let l:run_opts.on_stdout = s:MakeStdoutCb(l:stdout)
  let l:run_opts.on_stderr = s:MakeStderrCb(l:stderr)

  let OnSuccess = get(l:opts, 'on_success', v:null)
  let OnFailure = get(l:opts, 'on_failure', v:null)
  let OnExit    = get(l:opts, 'on_exit', v:null)

  let l:run_opts.on_exit = s:MakeExitCb(l:name, l:bufnr, l:stdout, l:stderr, OnSuccess, OnFailure, OnExit)

  try
    let l:run_id = ghostgit#job#Run(l:cmd, l:run_opts)
    if has_key(s:named_jobs, l:name)
      let s:named_jobs[l:name].run_id = l:run_id
    endif
  catch
    let s:running -= 1
    call s:CleanupNamed(l:name)
    let s:stats.failed += 1

    if OnFailure != v:null
      try
        call OnFailure([])
      catch
      endtry
    endif
    call s:ProcessQueue()
  endtry
endfunction

" Handle job exit: dispatch to callbacks, manage queue, update stats.
function! s:HandleExit(name, bufnr, stdout, stderr, code,
      \ on_success, on_failure, on_exit) abort
  let s:running -= 1
  call s:CleanupNamed(a:name)

  if a:code == 0
    let s:stats.completed += 1
  else
    let s:stats.failed += 1
  endif

  " Check buffer liveness — if the target buffer is gone, skip callbacks
  if a:bufnr > 0 && !bufexists(a:bufnr)
    call s:ProcessQueue()
    return
  endif

  try
    if a:code == 0 && a:on_success != v:null
      call a:on_success(a:stdout)
    elseif a:code != 0 && a:on_failure != v:null
      call a:on_failure(a:stderr)
    endif
  catch
    call ghostgit#util#Warn('ghostgit: Job callback error: ' . v:exception)
  endtry

  if a:on_exit != v:null
    try
      call a:on_exit(a:name, a:code)
    catch
    endtry
  endif

  call s:ProcessQueue()
endfunction

" Timer callback: execute a debounced job.
function! s:ExecuteDebounced(name, cmd, opts) abort
  if has_key(s:debounce_timers, a:name)
    unlet s:debounce_timers[a:name]
  endif
  call ghostgit#job#Schedule(a:name, a:cmd, a:opts)
endfunction

" Remove a name from the named-jobs index.
function! s:CleanupNamed(name) abort
  if has_key(s:named_jobs, a:name)
    unlet s:named_jobs[a:name]
  endif
endfunction

" ============================================================================
" Existing internals (unchanged)
" ============================================================================

function! s:Cleanup(job_id) abort
  if has_key(s:jobs, a:job_id)
    unlet s:jobs[a:job_id]
  endif
endfunction

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

  try
    let l:raw_id = jobstart(a:cmd, l:job_opts)
    let s:jobs[l:id] = {'raw': l:raw_id}
    return l:id
  catch
    call s:Cleanup(l:id)
    throw 'ghostgit: Failed to start Neovim job: ' . v:exception
  endtry
endfunction

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

  try
    let l:job = job_start(a:cmd, l:job_opts)
    let s:jobs[l:id] = {'job': l:job}
    return l:id
  catch
    call s:Cleanup(l:id)
    throw 'ghostgit: Failed to start Vim8 job: ' . v:exception
  endtry
endfunction

function! s:SyncRun(cmd, opts) abort
  let l:cwd = get(a:opts, 'cwd', getcwd())
  let l:saved = getcwd()
  let l:output = []
  let l:exit_code = 0

  try
    execute 'cd ' . fnameescape(l:cwd)
    let l:output = systemlist(a:cmd)
    let l:exit_code = v:shell_error
    execute 'cd ' . fnameescape(l:saved)
  catch
    execute 'cd ' . fnameescape(l:saved)
    throw 'ghostgit: Failed to execute command: ' . v:exception
  endtry

  let OnStdout = get(a:opts, 'on_stdout', v:null)
  let OnExit = get(a:opts, 'on_exit', v:null)

  if OnStdout != v:null
    try
      call OnStdout(0, l:output)
    catch
    endtry
  endif

  if OnExit != v:null
    try
      call OnExit(-1, l:exit_code)
    catch
    endtry
  endif

  return -1
endfunction
