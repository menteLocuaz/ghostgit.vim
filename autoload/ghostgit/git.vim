" ============================================================================
" ghostgit.vim - Git Command Wrappers
" ============================================================================

" Get repository status
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

  return ghostgit#core#Run(l:args, l:cwd)
endfunction

" Add file to staging area
function! ghostgit#git#Add(file, ...) abort
  let l:cwd = get(a:000, 0, '')
  return ghostgit#core#Run(['add', '--', a:file], l:cwd)
endfunction

" Remove file from staging area
function! ghostgit#git#Reset(file, ...) abort
  let l:cwd = get(a:000, 0, '')
  return ghostgit#core#Run(['reset', 'HEAD', '--', a:file], l:cwd)
endfunction

" Get diff from a file
function! ghostgit#git#Diff(file, ...) abort
  let l:extra_args = get(a:000, 0, '')
  let l:cwd = get(a:000, 1, '')
  
  let l:args = ['diff']
  
  if !empty(l:extra_args)
    if type(l:extra_args) == v:t_string
      let l:extra_list = split(l:extra_args, '\s\+')
      call extend(l:args, l:extra_list)
    else
      call add(l:args, l:extra_args)
    endif
  endif
  
  call add(l:args, '--')
  call add(l:args, a:file)
  
  return ghostgit#core#Run(l:args, l:cwd)
endfunction

" Get files in staging
function! ghostgit#git#GetStagedFiles(...) abort
  let l:cwd = get(a:000, 0, '')
  return ghostgit#core#Run(['diff', '--cached', '--name-only'], l:cwd)
endfunction

" Obtain modified files, but not staging files
function! ghostgit#git#GetModifiedFiles(...) abort
  let l:cwd = get(a:000, 0, '')
  return ghostgit#core#Run(['diff', '--name-only'], l:cwd)
endfunction

" Get untracked files
function! ghostgit#git#GetUntrackedFiles(...) abort
  let l:cwd = get(a:000, 0, '')
  return ghostgit#core#Run(['ls-files', '--others', '--exclude-standard'], l:cwd)
endfunction

" Commit staging changes
function! ghostgit#git#Commit(message, ...) abort
  let l:options = get(a:000, 0, [])
  let l:cwd = get(a:000, 1, '')
  
  let l:args = ['commit', '-m', a:message]
  
  if !empty(l:options)
    if type(l:options) == v:t_list
      call extend(l:args, l:options)
    else
      call add(l:args, l:options)
    endif
  endif
  
  return ghostgit#core#Run(l:args, l:cwd)
endfunction

" Get list of commits
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
  let l:options = get(a:000, 0, [])
  let l:cwd = get(a:000, 1, '')
  
  let l:args = ['checkout']
  
  if !empty(l:options)
    if type(l:options) == v:t_list
      call extend(l:args, l:options)
    else
      call add(l:args, l:options)
    endif
  endif
  
  call add(l:args, a:branch)
  return ghostgit#core#Run(l:args, l:cwd)
endfunction

" Push changes
function! ghostgit#git#Push(...) abort
  let l:options = get(a:000, 0, [])
  let l:cwd = get(a:000, 1, '')
  
  let l:args = ['push']
  
  if empty(l:options)
    call add(l:args, '--set-upstream')
    call add(l:args, 'origin')
    let l:current_branch = ghostgit#core#CurrentBranch(l:cwd)
    if !empty(l:current_branch)
      call add(l:args, l:current_branch)
    endif
  else
    if type(l:options) == v:t_list
      call extend(l:args, l:options)
    else
      call add(l:args, l:options)
    endif
  endif
  
  return ghostgit#core#Run(l:args, l:cwd)
endfunction

" Shift pull
function! ghostgit#git#Pull(...) abort
  let l:options = get(a:000, 0, [])
  let l:cwd = get(a:000, 1, '')
  
  let l:args = ['pull']
  
  if !empty(l:options)
    if type(l:options) == v:t_list
      call extend(l:args, l:options)
    else
      call add(l:args, l:options)
    endif
  endif
  
  return ghostgit#core#Run(l:args, l:cwd)
endfunction
