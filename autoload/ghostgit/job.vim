" ============================================================================
" ghostgit.vim - Async Job Runner
" ============================================================================
" Abstracts jobstart() (Neovim), job_start() (Vim8), and systemlist()
" fallback behind a single interface.

let s:job_id = 0
let s:jobs = {}

" Check if true async jobs are available
" @return {number} 1 if async jobs are available, 0 otherwise
function! ghostgit#job#IsAvailable() abort
  if has('nvim')
    return exists('*jobstart') ? 1 : 0
  elseif has('job')
    return 1
  endif
  return 0
endfunction

" Run a command asynchronously or synchronously as fallback
" @param {string|list} cmd - Command string or list of command arguments
" @param {dict} opts - Options dictionary with optional keys:
"   cwd       - Working directory (default: getcwd())
"   on_stdout - Callback funcref(channel, lines) for stdout lines
"   on_stderr - Callback funcref(channel, lines) for stderr lines
"   on_exit   - Callback funcref(job, exit_code) on completion
" @return {number} Job ID (>= 0) if async, -1 if sync fallback was used
function! ghostgit#job#Run(cmd, opts) abort
  " Validate inputs
  if empty(a:cmd)
    throw 'ghostgit: Command cannot be empty'
  endif

  " Normalize command to list format
  let l:cmd = type(a:cmd) == v:t_list ? copy(a:cmd) : split(a:cmd)
  let l:opts = a:opts

  " Dispatch to appropriate runner based on Vim version
  if has('nvim') && exists('*jobstart')
    return s:NvimRun(l:cmd, l:opts)
  elseif has('job')
    return s:Vim8Run(l:cmd, l:opts)
  else
    return s:SyncRun(l:cmd, l:opts)
  endif
endfunction

" Wait for a job to finish (no-op for sync fallback)
" @param {number} job_id - Job identifier
function! ghostgit#job#Wait(job_id) abort
  " Early return for invalid job IDs or sync jobs
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
    " Silently handle errors to prevent breaking user workflows
  endtry
endfunction

" Stop a running job (no-op for sync fallback)
" @param {number} job_id - Job identifier
function! ghostgit#job#Stop(job_id) abort
  " Early return for invalid job IDs or sync jobs
  if a:job_id < 0 | return | endif

  try
    if has('nvim') && exists('*jobstop')
      call jobstop(a:job_id)
    elseif has('job') && has_key(s:jobs, a:job_id)
      let l:job = s:jobs[a:job_id].job
      call job_stop(l:job)
    endif
  catch
    " Silently handle errors to prevent breaking user workflows
  endtry
endfunction

" Clean up stored state for a finished/stopped job
" @param {number} job_id - Job identifier
function! s:Cleanup(job_id) abort
  if has_key(s:jobs, a:job_id)
    unlet s:jobs[a:job_id]
  endif
endfunction

" ============================================================================
" Neovim: jobstart()
" ============================================================================
" Run command using Neovim's job control
" @param {list} cmd - Command arguments list
" @param {dict} opts - Options dictionary
" @return {number} Job identifier
function! s:NvimRun(cmd, opts) abort
  let s:job_id += 1
  let l:id = s:job_id
  let l:cwd = get(a:opts, 'cwd', getcwd())

  " Build job options
  let l:job_opts = {'cwd': l:cwd}

  " Set up stdout callback if provided
  if has_key(a:opts, 'on_stdout')
    let l:Cb = a:opts.on_stdout
    let l:job_opts.on_stdout = {ch, data -> l:Cb(ch, data)}
  endif

  " Set up stderr callback if provided
  if has_key(a:opts, 'on_stderr')
    let l:Cb = a:opts.on_stderr
    let l:job_opts.on_stderr = {ch, data -> l:Cb(ch, data)}
  endif

  " Set up exit callback if provided
  if has_key(a:opts, 'on_exit')
    let l:Cb = a:opts.on_exit
    let l:job_opts.on_exit = {job, code, event -> l:Cb(job, code)}
  endif

  try
    let l:raw_id = jobstart(a:cmd, l:job_opts)
    let s:jobs[l:id] = {'raw': l:raw_id}
    return l:id
  catch
    " Cleanup on error and rethrow
    call s:Cleanup(l:id)
    throw 'ghostgit: Failed to start Neovim job: ' . v:exception
  endtry
endfunction

" ============================================================================
" Vim8: job_start()
" ============================================================================
" Run command using Vim8's job control
" @param {list} cmd - Command arguments list
" @param {dict} opts - Options dictionary
" @return {number} Job identifier
function! s:Vim8Run(cmd, opts) abort
  let s:job_id += 1
  let l:id = s:job_id
  let l:cwd = get(a:opts, 'cwd', getcwd())

  " Build job options
  let l:job_opts = {'cwd': l:cwd}

  " Set up stdout callback if provided
  if has_key(a:opts, 'on_stdout')
    let l:Cb = a:opts.on_stdout
    let l:job_opts.out_cb = {ch, msg -> l:Cb(ch, [msg])}
  endif

  " Set up stderr callback if provided
  if has_key(a:opts, 'on_stderr')
    let l:Cb = a:opts.on_stderr
    let l:job_opts.err_cb = {ch, msg -> l:Cb(ch, [msg])}
  endif

  " Set up exit callback if provided
  if has_key(a:opts, 'on_exit')
    let l:Cb = a:opts.on_exit
    let l:job_opts.exit_cb = {job, code -> l:Cb(job, code)}
  endif

  try
    let l:job = job_start(a:cmd, l:job_opts)
    let s:jobs[l:id] = {'job': l:job}
    return l:id
  catch
    " Cleanup on error and rethrow
    call s:Cleanup(l:id)
    throw 'ghostgit: Failed to start Vim8 job: ' . v:exception
  endtry
endfunction

" ============================================================================
" Fallback: systemlist() synchronous
" ============================================================================
" Run command synchronously using systemlist as fallback
" @param {list} cmd - Command arguments list
" @param {dict} opts - Options dictionary
" @return {number} -1 indicating sync execution
function! s:SyncRun(cmd, opts) abort
  let l:cwd = get(a:opts, 'cwd', getcwd())
  let l:saved = getcwd()
  let l:output = []
  let l:exit_code = 0

  try
    " Change to working directory
    execute 'cd ' . fnameescape(l:cwd)
    
    " Execute command and capture output
    let l:output = systemlist(a:cmd)
    let l:exit_code = v:shell_error
    
    " Restore original directory
    execute 'cd ' . fnameescape(l:saved)
  catch
    " Restore original directory on error
    execute 'cd ' . fnameescape(l:saved)
    throw 'ghostgit: Failed to execute command: ' . v:exception
  endtry

  " Extract callbacks
  let l:on_stdout = get(a:opts, 'on_stdout', v:null)
  let l:on_exit = get(a:opts, 'on_exit', v:null)

  " Call stdout callback if provided
  if l:on_stdout != v:null
    try
      call l:on_stdout(0, l:output)
    catch
      " Log callback error but don't fail the function
    endtry
  endif

  " Call exit callback if provided
  if l:on_exit != v:null
    try
      call l:on_exit(-1, l:exit_code)
    catch
      " Log callback error but don't fail the function
    endtry
  endif

  return -1
endfunction
