" ============================================================================
" ghostgit.vim - Git Command Wrappers
" ============================================================================

" Get repository status
" a:000[0] - Optional callback for async execution
" a:000[1] - Optional working directory
function! ghostgit#git#Status(...) abort
  let l:callback = get(a:000, 0, v:null)
  let l:cwd = get(a:000, 1, '')

  let l:args = ['status', '--short', '--branch']

  if l:callback != v:null
    let l:stdout = []
    return ghostgit#job#Run(['git'] + l:args, {
          \ 'cwd': l:cwd,
          \ 'on_stdout': {ch, data -> extend(l:stdout, data)},
          \ 'on_exit': {job, code -> l:callback(l:stdout, code)}
          \ })
  endif

  " Verify that we are in a repository (sync fallback)
  return ghostgit#core#Run(l:args, l:cwd)
endfunction

" Add file to staging area
function! ghostgit#git#Add(file, ...) abort
  " Validate arguments
  if empty(a:file)
    call ghostgit#util#Error('File path cannot be empty')
    return []
  endif
  
  " Get optional working directory
  let l:cwd = get(a:000, 0, '')
  
  " Run the command git add
  return ghostgit#core#Run(['add', '--', a:file], l:cwd)
endfunction

" Remove file from staging area
function! ghostgit#git#Reset(file, ...) abort
  " Validate arguments
  if empty(a:file)
    call ghostgit#util#Error('File path cannot be empty')
    return []
  endif
  
  " Get optional working directory
  let l:cwd = get(a:000, 0, '')
  
  " Run the command git reset
  return ghostgit#core#Run(['reset', 'HEAD', '--', a:file], l:cwd)
endfunction

" Get diff from a file
function! ghostgit#git#Diff(file, ...) abort
  " Validate arguments
  if empty(a:file)
    call ghostgit#util#Error('File path cannot be empty')
    return []
  endif
  
  " Obtain additional arguments and working directory
  let l:extra_args = get(a:000, 0, '')
  let l:cwd = get(a:000, 1, '')
  
  " Build command git diff
  let l:args = ['diff']
  
  " Add additional arguments if they exist
  if !empty(l:extra_args)
    if type(l:extra_args) == v:t_string
      let l:extra_list = split(l:extra_args, '\s\+')
      call extend(l:args, l:extra_list)
    else
      call add(l:args, l:extra_args)
    endif
  endif
  
  " Add separator and filename
  call add(l:args, '--')
  call add(l:args, a:file)
  
  " Run command
  return ghostgit#core#Run(l:args, l:cwd)
endfunction

" Get files in staging
function! ghostgit#git#GetStagedFiles(...) abort
  let l:cwd = get(a:000, 0, '')
  " Run `git diff` with `--cached` to get staging files
  return ghostgit#core#Run(['diff', '--cached', '--name-only'], l:cwd)
endfunction

" Obtain modified files, but not staging files
function! ghostgit#git#GetModifiedFiles(...) abort
  let l:cwd = get(a:000, 0, '')
  " Run `git diff` to get modified files
  return ghostgit#core#Run(['diff', '--name-only'], l:cwd)
endfunction

" Get untracked files
function! ghostgit#git#GetUntrackedFiles(...) abort
  let l:cwd = get(a:000, 0, '')
  " Run `git ls-files` to get untracked files
  return ghostgit#core#Run(['ls-files', '--others', '--exclude-standard'], l:cwd)
endfunction

" Commit staging changes
function! ghostgit#git#Commit(message, ...) abort
  " Validate commit message
  if empty(a:message)
    call ghostgit#util#Error('Commit message cannot be empty')
    return []
  endif
  
  " Get additional options
  let l:options = get(a:000, 0, [])
  let l:cwd = get(a:000, 1, '')
  
  " Build command git commit
  let l:args = ['commit', '-m', a:message]
  
  " Add additional options if available
  if !empty(l:options)
    if type(l:options) == v:t_list
      call extend(l:args, l:options)
    else
      call add(l:args, l:options)
    endif
  endif
  
  " Run command
  return ghostgit#core#Run(l:args, l:cwd)
endfunction

" Get list of commits
" a:000[0] - Optional callback for async execution
" a:000[1] - Optional working directory
function! ghostgit#git#Log(...) abort
  let l:callback = get(a:000, 0, v:null)
  let l:cwd = get(a:000, 1, '')

  let l:args = ['log', '--oneline', '--decorate', '--graph', '-100']

  if l:callback != v:null
    let l:stdout = []
    return ghostgit#job#Run(['git'] + l:args, {
          \ 'cwd': l:cwd,
          \ 'on_stdout': {ch, data -> extend(l:stdout, data)},
          \ 'on_exit': {job, code -> l:callback(l:stdout, code)}
          \ })
  endif

  return ghostgit#core#Run(l:args, l:cwd)
endfunction

" Create new branch
function! ghostgit#git#Checkout(branch, ...) abort
  " Validate branch name
  if empty(a:branch)
    call ghostgit#util#Error('Branch name cannot be empty')
    return []
  endif
  
  " Get additional options
  let l:options = get(a:000, 0, [])
  let l:cwd = get(a:000, 1, '')
  
  " Build git checkout command
  let l:args = ['checkout']
  
  " Add additional options if available
  if !empty(l:options)
    if type(l:options) == v:t_list
      call extend(l:args, l:options)
    else
      call add(l:args, l:options)
    endif
  endif
  
  " Add branch name
  call add(l:args, a:branch)
  
  " Run command
  return ghostgit#core#Run(l:args, l:cwd)
endfunction

" Push changes
function! ghostgit#git#Push(...) abort
  let l:options = get(a:000, 0, [])
  let l:cwd = get(a:000, 1, '')
  
  " Build command git push
  let l:args = ['push']
  
  " Add default option if there are no options
  if empty(l:options)
    call add(l:args, '--set-upstream')
    call add(l:args, 'origin')
    let l:current_branch = ghostgit#core#CurrentBranch(l:cwd)
    if !empty(l:current_branch)
      call add(l:args, l:current_branch)
    endif
  else
    " Add additional options if available
    if type(l:options) == v:t_list
      call extend(l:args, l:options)
    else
      call add(l:args, l:options)
    endif
  endif
  
  " Run command
  return ghostgit#core#Run(l:args, l:cwd)
endfunction

" Shift pull
function! ghostgit#git#Pull(...) abort
  let l:options = get(a:000, 0, [])
  let l:cwd = get(a:000, 1, '')
  
  " Build command git pull
  let l:args = ['pull']
  
  " Add additional options if available
  if !empty(l:options)
    if type(l:options) == v:t_list
      call extend(l:args, l:options)
    else
      call add(l:args, l:options)
    endif
  endif
  
  " Run command
  return ghostgit#core#Run(l:args, l:cwd)
endfunction
