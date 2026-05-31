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

" Cache for completion results
let s:cache = {}
let s:cache_ttl = 2 " 2 seconds

function! s:GetCached(key, Func) abort
  let l:now = localtime()
  if has_key(s:cache, a:key)
    let l:entry = s:cache[a:key]
    if l:now - l:entry.time < s:cache_ttl
      return l:entry.data
    endif
  endif

  let l:data = a:Func()
  let s:cache[a:key] = {'time': l:now, 'data': l:data}
  return l:data
endfunction

function! ghostgit#complete#ClearCache() abort
  let s:cache = {}
endfunction

function! ghostgit#complete#Branches() abort
  " Verify that we are in a Git repository
  let l:root = ghostgit#core#RepoRoot()
  if empty(l:root) 
    return [] 
  endif

  return s:GetCached('branches:' . l:root, {-> 
        \ ghostgit#core#Run(['branch', '--format', '%(refname:short)'], l:root) +
        \ ghostgit#core#Run(['branch', '-r', '--format', '%(refname:short)'], l:root)
        \ })
endfunction

" Retrieves modified files from the repository
function! ghostgit#complete#ModifiedFiles() abort
  " Verify that we are in a Git repository
  let l:root = ghostgit#core#RepoRoot()
  if empty(l:root) 
    return [] 
  endif

  return s:GetCached('modified:' . l:root, {-> 
        \ map(filter(ghostgit#core#Run(['status', '--porcelain'], l:root), 'len(v:val) > 3'), 'v:val[3:]')
        \ })
endfunction

" It retrieves files that are in the staging area
function! ghostgit#complete#StagedFiles() abort
  " Verify that we are in a Git repository
  let l:root = ghostgit#core#RepoRoot()
  if empty(l:root) 
    return [] 
  endif

  return s:GetCached('staged:' . l:root, {-> 
        \ ghostgit#core#Run(['diff', '--name-only', '--cached'], l:root)
        \ })
endfunction

" Retrieves the remotes configured in the repository
function! ghostgit#complete#Remotes() abort
  " Verify that we are in a Git repository
  let l:root = ghostgit#core#RepoRoot()
  if empty(l:root) 
    return [] 
  endif

  return s:GetCached('remotes:' . l:root, {-> ghostgit#core#Run(['remote'], l:root)})
endfunction

" Get the tags from the repository
function! ghostgit#complete#Tags() abort
  " Verify that we are in a Git repository
  let l:root = ghostgit#core#RepoRoot()
  if empty(l:root) 
    return [] 
  endif

  return s:GetCached('tags:' . l:root, {-> ghostgit#core#Run(['tag'], l:root)})
endfunction

" Retrieves all files tracked by Git
function! ghostgit#complete#TrackedFiles() abort
  " Verify that we are in a Git repository
  let l:root = ghostgit#core#RepoRoot()
  if empty(l:root) 
    return [] 
  endif

  return s:GetCached('tracked:' . l:root, {-> ghostgit#core#Run(['ls-files'], l:root)})
endfunction

" Get the list of available stashes
function! ghostgit#complete#Stashes() abort
  " Verify that we are in a Git repository
  let l:root = ghostgit#core#RepoRoot()
  if empty(l:root) 
    return [] 
  endif

  return s:GetCached('stashes:' . l:root, {-> ghostgit#core#Run(['stash', 'list', '--format', '%gd'], l:root)})
endfunction
