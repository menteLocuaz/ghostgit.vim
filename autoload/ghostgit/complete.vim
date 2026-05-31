" ============================================================================
" ghostgit.vim - Git Command Completion for :Git and :G
" ============================================================================

" Función principal para autocompletar comandos Git
" A: Current argument being completed
" L: Complete command line
" P: Cursor position
function! ghostgit#complete#Complete(A, L, P) abort
  " Divide the line into arguments
  let l:args = split(a:L)
  
  " Get the subcommand (first argument after the main command)
  let l:subcmd = get(l:args, 1, '')

  " If we only have the main command, show available subcommands
  if len(l:args) <= 1
    return ghostgit#complete#Subcommands()
  endif

  " Otherwise, provide specific context for the subcommand
  return ghostgit#complete#Context(l:subcmd)
endfunction

" Returns a list of common Git subcommands
function! ghostgit#complete#Subcommands() abort
  return [
        \ 'add', 'bisect', 'branch', 'checkout', 'clone', 'commit',
        \ 'diff', 'fetch', 'grep', 'init', 'log', 'merge', 'mv', 'pull',
        \ 'push', 'rebase', 'reset', 'restore', 'rm', 'show', 'status',
        \ 'stash', 'switch', 'tag'
        \]
endfunction

" Provides contextual autocomplete based on the subcommand
function! ghostgit#complete#Context(subcmd) abort
  " Commands that require branches as an argument
  if a:subcmd =~# '^\(checkout\|switch\|branch\|merge\|rebase\|log\|show\)$'
    return ghostgit#complete#Branches()
  
  " Commands that require modified files
  elseif a:subcmd =~# '^\(add\|restore\)$'
    return ghostgit#complete#ModifiedFiles()
  
  " Commands that require staging files
  elseif a:subcmd ==# 'reset'
    return ghostgit#complete#StagedFiles()
  
  " Commands that may require both branches and modified files
  elseif a:subcmd ==# 'diff'
    return ghostgit#complete#Branches() + ghostgit#complete#ModifiedFiles()
  
  " Commands that require remote access
  elseif a:subcmd ==# 'remote'
    return ghostgit#complete#Remotes()
  
  " Commands that require tags
  elseif a:subcmd ==# 'tag'
    return ghostgit#complete#Tags()
  
  " Commands that require tracked files
  elseif a:subcmd =~# '^\(rm\|mv\)$'
    return ghostgit#complete#TrackedFiles()
  
  " Commands that require stashes
  elseif a:subcmd ==# 'stash'
    return ghostgit#complete#Stashes()
  endif

  " Return an empty list if there are no matches
  return []
endfunction

" It retrieves all local and remote branches from the repository
function! ghostgit#complete#Branches() abort
  " Verify that we are in a Git repository
  let l:root = ghostgit#core#RepoRoot()
  if empty(l:root) 
    return [] 
  endif

  try
    " Get local branches
    let l:local = ghostgit#core#Run(['branch', '--format', '%(refname:short)'], l:root)
    
    " Get remote branches
    let l:remote = ghostgit#core#Run(['branch', '-r', '--format', '%(refname:short)'], l:root)
    
    " Combine results
    return l:local + l:remote
  catch
    " In case of error, return an empty list
    return []
  endtry
endfunction

" Retrieves modified files from the repository
function! ghostgit#complete#ModifiedFiles() abort
  " Verify that we are in a Git repository
  let l:root = ghostgit#core#RepoRoot()
  if empty(l:root) 
    return [] 
  endif

  try
    let l:files = []
    " Run the git status command in machine format
    for l:line in ghostgit#core#Run(['status', '--porcelain'], l:root)
      " Verify that the line is long enough
      if len(l:line) > 3
        " Extract filename (after status)
        call add(l:files, l:line[3:])
      endif
    endfor

    return l:files
  catch
    return []
  endtry
endfunction

" It retrieves files that are in the staging area
function! ghostgit#complete#StagedFiles() abort
  " Verify that we are in a Git repository
  let l:root = ghostgit#core#RepoRoot()
  if empty(l:root) 
    return [] 
  endif

  try
    return ghostgit#core#Run(['diff', '--name-only', '--cached'], l:root)
  catch
    return []
  endtry
endfunction

" Retrieves the remotes configured in the repository
function! ghostgit#complete#Remotes() abort
  " Verify that we are in a Git repository
  let l:root = ghostgit#core#RepoRoot()
  if empty(l:root) 
    return [] 
  endif

  try
    return ghostgit#core#Run(['remote'], l:root)
  catch
    return []
  endtry
endfunction

" Get the tags from the repository
function! ghostgit#complete#Tags() abort
  " Verify that we are in a Git repository
  let l:root = ghostgit#core#RepoRoot()
  if empty(l:root) 
    return [] 
  endif

  try
    return ghostgit#core#Run(['tag'], l:root)
  catch
    return []
  endtry
endfunction

" Retrieves all files tracked by Git
function! ghostgit#complete#TrackedFiles() abort
  " Verify that we are in a Git repository
  let l:root = ghostgit#core#RepoRoot()
  if empty(l:root) 
    return [] 
  endif

  try
    return ghostgit#core#Run(['ls-files'], l:root)
  catch
    return []
  endtry
endfunction

" Get the list of available stashes
function! ghostgit#complete#Stashes() abort
  " Verify that we are in a Git repository
  let l:root = ghostgit#core#RepoRoot()
  if empty(l:root) 
    return [] 
  endif

  try
    return ghostgit#core#Run(['stash', 'list', '--format', '%gd: %gs'], l:root)
  catch
    return []
  endtry
endfunction