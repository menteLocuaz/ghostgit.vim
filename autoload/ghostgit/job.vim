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