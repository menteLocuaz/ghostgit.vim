" ============================================================================
" ghostgit.vim - Core Git API
" ============================================================================

" Run a git command and return output
function! ghostgit#core#Run(args, ...) abort
  " Get the working directory
  let l:cwd = get(a:000, 0, '')
  if empty(l:cwd)
    let l:cwd = getcwd()
  endif

  " Verify that the directory exists
  if !isdirectory(l:cwd)
    call ghostgit#util#Error('Directory does not exist: ' . l:cwd)
    return []
  endif

" Build git command
  if type(a:args) == v:t_list
    let l:cmd = ['git'] + a:args
  else
    let l:cmd = ['git', a:args]
  endif

" Use temporary directory for command execution
  let l:saved_cwd = getcwd()
  try
    execute 'cd ' . fnameescape(l:cwd)
    let l:output = systemlist(l:cmd)
    let l:exit = v:shell_error
  catch
    " Restore directory in case of error
    execute 'cd ' . fnameescape(l:saved_cwd)
    call ghostgit#util#Error('Failed to execute git command: ' . v:exception)
    return []
  finally
    " Always restore the original directory
    execute 'cd ' . fnameescape(l:saved_cwd
  endtry

" Handling Git errors
  if l:exit != 0
    " For some commands, the exit code != 0 may be valid
    " For example, 'git rev-parse --verify HEAD' fails on empty repositories
    " But in most cases, we show an error
    call ghostgit#util#Error('Git command failed (' . l:exit . '): ' . join(l:cmd, ' ') . "\n" . join(l:output,"\n"))
    return l:output " Return output even in case of error so the caller can decide
  endif

  return l:output
endfunction

" Return root from current repo
function! ghostgit#core#RepoRoot(...) abort
  " Get job directory
  let l:cwd = get(a:000, 0, '')
  if empty(l:cwd)
    let l:cwd = getcwd()
  endif

  " Verify cache first
  let l:entry = ghostgit#state#GetRepo(l:cwd)
  if !empty(l:entry) &&   if !empty(l:entry) && !empty(get(l:entry, 'git_dir', ''))
    return l:entry.git_dir
  endif

  " Run the git command to get root access
  let l:result = ghostgit#core#Run(['rev-parse', '--show-toplevel'], l:cwd)

  " Check result
  if !empty(l:result) && !empty(l:result[0])
    let l:root = l:result[0]

    " validate that the result is a valid directory
    if isdirectory(l:root)
      " Cached
      call ghostgit#state#SetRepo(l:root)
      if !has_key(g:ghostgit_state.repos[l:root], 'git_dir')
        let g:ghostgit_state.repos[l:root].git_dir = l:root
      endif
      return l:root
    else
      call ghostgit#util#Warn('Git root is not a valid directory: ' . l:root)
    endif
  endif

  return ''
endfunction

" Return current branch
function! ghostgit#core#CurrentBranch(...) abort
  " Get job directory
  let l:cwd = get(a:000, 0, '')
  if empty(l:cwd)
    let l:cwd = getcwd()
  endif

  " Verify that we are in a repository
  if !ghostgit#core#IsRepo(l:cwd)
    return ''
  endif

  " Run command to get branch
  let l:result = ghostgit#core#Run(['rev-parse', '--abbrev-ref', 'HEAD'], l:cwd)

  " Process result
  if !empty(l:result) && !empty(l:result[0])
    " Handling special case of HEAD detached
    if l:result[0] == 'HEAD'
      " Get commit hash instead of HEAD
      let l:hash_result = ghostgit#core#Run(['rev-parse', '--short', 'HEAD'], l:cwd)
      if !empty(l:hash_result) && !empty(l:hash_result[0]) 
        return 'HEAD detached at ' . l:hash_result[0]
      endif
    endif
    return l:result[0]
  endif

  return ''
endfunction

" Check if the current directory is a git repository
function! ghostgit#core#IsRepo(...) abort
  " Get job directory
  let l:cwd = get(a:000, 0, '')
  if empty(l:cwd)
    let l:cwd = getcwd()
  endif

  " Verify cache first for better performance
  let l:entry = ghostgit#state#GetRepo(l:cwd)
  if !empty(l:entry) && get(l:entry, 'is_repo', 0)
    return l:entry.is_repo
  endif 

  " Run the git command to check if it's a repository
  let l:output = ghostgit#core#Run(['rev-parse', '--git-dir'], l:cwd)

  " Determine if it is an output-based repository and output code
  let l:is_repo = v:shell_error == 0 && !empty(l:output)

  " Cached
  call ghostgit#state#SetRepo(l:cwd, {'is_repo': l:is_repo})

  return l:is_repo
endfunction

" Get list of branches
function! ghostgit#core#ListBranches(...) abort
  " Get job directory
  let l:cwd = get(a:000, 0, '')
  if empty(l:cwd)
    let l:cwd = getcwd() 
  endif

  " Verify that we are in a repository
  if !ghostgit#core#IsRepo(l:cwd)
    return []
  endif

  " Get local branches
  let l:local_branches = ghostgit#core#Run(['branch', '--format', '%(refname:short)'], l:cwd)

  " Obtain remote branches
  let l:remote_branches = ghostgit#core#Run(['branch', '-r', '--format', '%(refname:short)'], l:cwd)

  " Combine results
  return l:local_branches + l:remote_branches
endfunction

" Get latest commit
function! ghostgit#core#LastCommit(...) abort 
  " Get job directory
  let l:cwd = get(a:000, 0, '')
  if empty(l:cwd)
    let l:cwd = getcwd()
  endif

  " Verify that we are in a repository
  if !ghostgit#core#IsRepo(l:cwd)
    return {}
  endif

  " Get information about the last commit
  let l:hash = ghostgit#core#Run(['rev-parse', 'HEAD'], l:cwd)
  let l:subject = ghostgit#core#Run(['log', '-1', '--format=%s'], l:cwd)
  let l:author = ghostgit#core#Run(['log', '-1', '--format=%an'], l:cwd)
  let l:date = ghostgit#core#Run(['log', '-1', '--format=%ad', '--date=relative'], l:cwd)

  " Verify that we have all the data
  if empty(l:hash) || empty(l:subject) || empty(l:author) || empty(l:date)
    return {}
  endif

  return {
    \ 'hash': l:hash[0], 
    \ 'subject': l:subject[0], 
    \ 'author': l:author[0],
    \ 'date': l:date[0] 
    \ } 
endfunction