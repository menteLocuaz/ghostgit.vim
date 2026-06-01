" ============================================================================
" ghostgit.vim - Git Command Wrappers
" ============================================================================

" Get repository status
function! ghostgit#git#Status(...) abort
  let l:cwd = ''
  let l:opts = {}
  
  if a:0 > 0
    if type(a:1) == v:t_func
      " Legacy support for callback as first arg
      let l:opts = {'on_exit': {job, code -> a:1([], code)}}
      let l:cwd = get(a:000, 1, '')
    elseif type(a:1) == v:t_dict
      let l:opts = a:1
      let l:cwd = get(a:000, 1, '')
    else
      let l:cwd = a:1
      let l:opts = get(a:000, 1, {})
    endif
  endif

  let l:args = ['status', '--short', '--branch']
  return ghostgit#core#Run(l:args, l:cwd, l:opts)
endfunction

" Add file(s) to staging area
function! ghostgit#git#Add(file, ...) abort
  if empty(a:file)
    call ghostgit#util#Error('File path cannot be empty')
    return []
  endif
  
  let l:cwd = ''
  let l:opts = {}
  if a:0 > 0
    if type(a:1) == v:t_dict
      let l:opts = a:1
      let l:cwd = get(a:000, 1, '')
    else
      let l:cwd = a:1
      let l:opts = get(a:000, 1, {})
    endif
  endif
  
  let l:files = type(a:file) == v:t_list ? a:file : [a:file]
  let l:args = ['add', '--'] + l:files
  return ghostgit#core#Run(l:args, l:cwd, l:opts)
endfunction

" Remove file from staging area or perform reset
function! ghostgit#git#Reset(file, ...) abort
  let l:cwd = ''
  let l:opts = {}
  if a:0 > 0
    if type(a:1) == v:t_dict
      let l:opts = a:1
      let l:cwd = get(a:000, 1, '')
    else
      let l:cwd = a:1
      let l:opts = get(a:000, 1, {})
    endif
  endif
  
  if type(a:file) == v:t_string && a:file =~# '^--'
    return ghostgit#core#Run(['reset', a:file], l:cwd, l:opts)
  endif
  
  if type(a:file) == v:t_list && empty(a:file)
    return ghostgit#core#Run(['reset', 'HEAD', '--', '.'], l:cwd, l:opts)
  endif

  if empty(a:file)
    call ghostgit#util#Error('File path cannot be empty')
    return []
  endif
  
  let l:files = type(a:file) == v:t_list ? a:file : [a:file]
  return ghostgit#core#Run(['reset', 'HEAD', '--'] + l:files, l:cwd, l:opts)
endfunction

" Get diff from a file
function! ghostgit#git#Diff(file, ...) abort
  let l:extra_args = get(a:000, 0, '')
  let l:cwd = ''
  let l:opts = {}
  
  if a:0 > 1
    if type(a:2) == v:t_dict
      let l:opts = a:2
      let l:cwd = a:1
    else
      let l:cwd = a:1
      let l:opts = get(a:000, 2, {})
    endif
  endif
  
  let l:args = ['diff']
  
  if !empty(l:extra_args)
    if type(l:extra_args) == v:t_string
      let l:extra_list = split(l:extra_args, '\s\+')
      call extend(l:args, l:extra_list)
    else
      call add(l:args, l:extra_args)
    endif
  endif
  
  if !empty(a:file)
    call add(l:args, '--')
    call add(l:args, a:file)
  endif
  
  return ghostgit#core#Run(l:args, l:cwd, l:opts)
endfunction

" Get files in staging
function! ghostgit#git#GetStagedFiles(...) abort
  let l:cwd = get(a:000, 0, '')
  let l:opts = get(a:000, 1, {})
  return ghostgit#core#Run(['diff', '--cached', '--name-only'], l:cwd, l:opts)
endfunction

" Obtain modified files, but not staging files
function! ghostgit#git#GetModifiedFiles(...) abort
  let l:cwd = get(a:000, 0, '')
  let l:opts = get(a:000, 1, {})
  return ghostgit#core#Run(['diff', '--name-only'], l:cwd, l:opts)
endfunction

" Get untracked files
function! ghostgit#git#GetUntrackedFiles(...) abort
  let l:cwd = get(a:000, 0, '')
  let l:opts = get(a:000, 1, {})
  return ghostgit#core#Run(['ls-files', '--others', '--exclude-standard'], l:cwd, l:opts)
endfunction

" Commit staging changes
function! ghostgit#git#Commit(message, ...) abort
  if empty(a:message)
    call ghostgit#util#Error('Commit message cannot be empty')
    return []
  endif
  
  let l:options = get(a:000, 0, [])
  let l:cwd = ''
  let l:opts = {}
  
  if a:0 > 1
    if type(a:2) == v:t_dict
      let l:opts = a:2
      let l:cwd = a:1
    else
      let l:cwd = a:1
      let l:opts = get(a:000, 2, {})
    endif
  endif
  
  let l:args = ['commit', '-m', a:message]
  
  if !empty(l:options)
    if type(l:options) == v:t_list
      call extend(l:args, l:options)
    else
      call add(l:args, l:options)
    endif
  endif
  
  return ghostgit#core#Run(l:args, l:cwd, l:opts)
endfunction

" Get list of commits
function! ghostgit#git#Log(...) abort
  let l:cwd = ''
  let l:opts = {}
  
  if a:0 > 0
    if type(a:1) == v:t_func
      " Legacy support
      let l:opts = {'on_exit': {job, code -> a:1([], code)}}
      let l:cwd = get(a:000, 1, '')
    elseif type(a:1) == v:t_dict
      let l:opts = a:1
      let l:cwd = get(a:000, 1, '')
    else
      let l:cwd = a:1
      let l:opts = get(a:000, 1, {})
    endif
  endif

  let l:args = ['log', '--oneline', '--decorate', '--graph', '-100']
  return ghostgit#core#Run(l:args, l:cwd, l:opts)
endfunction

" Create new branch
function! ghostgit#git#Checkout(branch, ...) abort
  if empty(a:branch)
    call ghostgit#util#Error('Branch name cannot be empty')
    return []
  endif
  
  let l:options = get(a:000, 0, [])
  let l:cwd = ''
  let l:opts = {}
  
  if a:0 > 1
    if type(a:2) == v:t_dict
      let l:opts = a:2
      let l:cwd = a:1
    else
      let l:cwd = a:1
      let l:opts = get(a:000, 2, {})
    endif
  endif
  
  let l:args = ['checkout']
  if !empty(l:options)
    call extend(l:args, l:options)
  endif
  call add(l:args, a:branch)
  
  return ghostgit#core#Run(l:args, l:cwd, l:opts)
endfunction

" Push changes
function! ghostgit#git#Push(...) abort
  let l:options = get(a:000, 0, [])
  let l:cwd = ''
  let l:opts = {}
  
  if a:0 > 1
    if type(a:2) == v:t_dict
      let l:opts = a:2
      let l:cwd = a:1
    else
      let l:cwd = a:1
      let l:opts = get(a:000, 2, {})
    endif
  endif
  
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
  
  return ghostgit#core#Run(l:args, l:cwd, l:opts)
endfunction

" List branches (returns raw branch list with * for current)
function! ghostgit#git#Branch(...) abort
  let l:cwd = get(a:000, 0, '')
  let l:opts = get(a:000, 1, {})
  return ghostgit#core#Run(['branch'], l:cwd, l:opts)
endfunction

" Shift pull
function! ghostgit#git#Pull(...) abort
  let l:options = get(a:000, 0, [])
  let l:cwd = ''
  let l:opts = {}
  
  if a:0 > 1
    if type(a:2) == v:t_dict
      let l:opts = a:2
      let l:cwd = a:1
    else
      let l:cwd = a:1
      let l:opts = get(a:000, 2, {})
    endif
  endif
  
  let l:args = ['pull']
  if !empty(l:options)
    if type(l:options) == v:t_list
      call extend(l:args, l:options)
    else
      call add(l:args, l:options)
    endif
  endif
  
  return ghostgit#core#Run(l:args, l:cwd, l:opts)
endfunction
