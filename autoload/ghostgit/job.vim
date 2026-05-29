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

  if ghostgit#job#IsNvim()
    return s:JobStartNvim(a:cmd, a:on_stdout, a:on_exit, l:cwd)
  elseif exists('*job_start')
    return s:JobStartVim8(a:cmd, a:on_stdout, a:on_exit, l:cwd)
  else
    " Run fallback only if there is no job support
    return s:JobFallback(a:cmd, a:on_exit, l:cwd)
  endif
endfunction

" Neovim job handler
function! s:JobStartNvim(cmd, on_stdout, on_exit, cwd) abort
  " Preparar opciones para Neovim
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
    throw "ghostgit#job#StartVim8: Failed to start job"
  endif
  
  return l:job
endfunction

" Fallback synchronous
function! s:JobFallback(cmd, on_exit, cwd) abort
  " Save the current directory and change to the specified one.
  let l:old_cwd = getcwd()
  execute "lcd " . fnameescape(a:cwd)
  
  try
    " Execute command and capture output
    let l:output = systemlist(a:cmd)
    let l:exit_code = v:shell_error
    
    " Restore original directory
    execute "lcd " . fnameescape(l:old_cwd)
    
    " Call output callback with simulated data
    call call(function(a:on_stdout), [[''], {'exit_code': l:exit_code}])
    
    " Call completion callback
    call call(function(a:on_exit), [l:exit_code])
    
    return { 'output': l:output, 'exit_code': l:exit_code }
  catch
    " Restore directory even if there are errors
    execute "lcd " . fnameescape(l:old_cwd)
    throw "ghostgit#JobFallback: " . v:exception
  endtry
endfunction