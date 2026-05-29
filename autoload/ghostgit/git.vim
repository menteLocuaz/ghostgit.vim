" ============================================================================
" ghostgit.vim - Git Command Wrappers
" ============================================================================

" Get repository status
function! ghostgit#git#Status(...) abort
  " Get optional working directory
  let l:cwd = get(a:000, 0, '')
  
  " Verify that we are in a repository
  if !empty(l:cwd) && !isdirectory(l:cwd)
    call ghostgit#util#Error('Directory does not exist: ' . l:cwd)
    return []
  endif
  
  " Run the `git status` command with options to get complete information
  return ghostgit#core#Run(['status', '--short', '--branch'], l:cwd)
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
  
  " Verify that the file exists
  if !empty(l:cwd)
    let l:full_path = fnameescape(l:cwd . '/' . a:file)
    if !filereadable(l:full_path) && !isdirectory(l:full_path)
      call ghostgit#util#Warn('File does not exist: ' . a:file)
      " Continue anyway since `git add` can handle this
    endif
  endif
  
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
    " Handling multiple arguments if passed as a string
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
  let l:output = ghostgit#core#Run(['diff', '--cached', '--name-only'], l:cwd)
  
  " Convert output to file list
  return l:output
endfunction

" Obtain modified files, but not staging files
function! ghostgit#git#GetModifiedFiles(...) abort
  let l:cwd = get(a:000, 0, '')
  
  " Run `git diff` to get modified files
  let l:output = ghostgit#core#Run(['diff', '--name-only'], l:cwd)
  
  return l:output
endfunction

" Get untracked files
function! ghostgit#git#GetUntrackedFiles(...) abort
  let l:cwd = get(a:000, 0, '')
  
  " Run `git ls-files` to get untracked files
  let l:output = ghostgit#core#Run(['ls-files', '--others', '--exclude-standard'], l:cwd)
  
  return l:output
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
function! ghostgit#git#Log(...) abort
  " Get additional options
  let l:options = get(a:000, 0, [])
  let l:cwd = get(a:000, 1, '')
  
  " Build command git log
  let l:args = ['log']
  
  " Add default options for readable formatting
  call extend(l:args, ['--oneline', '--graph', '--decorate'])
  
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