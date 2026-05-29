" ============================================================================
" ghostgit.vim - Diff Preview Buffer
" ============================================================================

" Open diff window for a file
function! ghostgit#diff#Open(file, ...) abort
  " Validate arguments
  if empty(a:file)
    call ghostgit#util#Error('No file specified for diff')
    return
  endif

  " Get additional arguments
  let l:extra_args = get(a:000, 0, '')
  
  " Build command git diff
  let l:args = ['diff']
  
  " Add additional arguments if they exist
  if !empty(l:extra_args)
    " Handling multiple arguments if passed as a string
    if type(l:extra_args) == v:t_string
      " Split string into argument list
      let l:extra_list = split(l:extra_args, '\s\+')
      call extend(l:args, l:extra_list)
    else
      call add(l:args, l:extra_args)
    endif
  endif

  " Add separator and filename
  call add(l:args, '--')
  call add(l:args, a:file)
  
  " Run the git diff command
  let l:lines = ghostgit#core#Run(l:args)
  
  " Check for differences
  if empty(l:lines)
    call ghostgit#util#Info('No differences for ' . a:file)
    return
  endif

  " Create or open diff buffer
  call ghostgit#util#OpenBuffer('diff/' . a:file, 'botright')
  
  " Render diff content
  call ghostgit#util#Render(l:lines)

  " Buffer configuration
  setlocal nomodifiable
  setlocal filetype=diff
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  
  " Set buffer title
  let &local.statusline='%#StatusLine#[GhostGit]\ Diff\ ' . a:file . '%='
  
  " Configure keyboard mappings
  nnoremap <silent><buffer> q :bd!<CR>
  nnoremap <silent><buffer> <C-c> :bd!<CR>
  nnoremap <silent><buffer> r :call ghostgit#diff#Refresh()<CR>
  
  " Save diff state information for possible refresh
  call ghostgit#state#SetBufferData('diff/' . a:file, {
        \ 'file': a:file,
        \ 'extra_args': l:extra_args
        \ })
endfunction

" Refresh current diff content
function! ghostgit#diff#Refresh() abort
  " Get current buffer
  let l:bufnr = bufnr('%')
  let l:bufname = bufname(l:bufnr)
  
  " Verify that we are in a diff buffer
  if l:bufname !~ '^diff/'
    call ghostgit#util#Error('Not in a diff buffer')
    return
  endif
  
  " Extract filename from buffer
  let l:file = substitute(l:bufname, '^diff/', '', '')
  
  " Get saved diff data
  let l:data = ghostgit#state#GetBufferData(l:bufname)
  let l:extra_args = get(l:data, 'extra_args', '')
  
  " Rebuild command
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
  call add(l:args, l:file)
  
  " Run command
  let l:lines = ghostgit#core#Run(l:args)
  
  " Check results
  if empty(l:lines)
    call ghostgit#util#Info('No differences for ' . l:file)
    return
  endif
  
  " Update content
  setlocal modifiable
  call ghostgit#util#Render(l:lines)
  setlocal nomodifiable
  
  call ghostgit#util#Info('Diff refreshed for ' . l:file)
endfunction

" Open diff of all files in staging
function! ghostgit#diff#OpenStaged() abort
  " Verify that we are in a repository
  if !ghostgit#core#IsRepo()
    call ghostgit#util#Error('Not in a git repository')
    return
  endif
  
  " Get files in staging
  let l:staged_files = ghostgit#git#GetStagedFiles()
  
  " Verify that there are files in staging
  if empty(l:staged_files)
    call ghostgit#util#Info('No staged files to diff')
    return
  endif
  
  " Create buffer for combined diff
  call ghostgit#util#OpenBuffer('diff/staged', 'botright')
  
  " Accumulate diffs from all files
  let l:all_lines = ['=== Staged Changes ===', '']
  
  for l:file in l:staged_files
    let l:lines = ghostgit#core#Run(['diff', '--cached', '--', l:file])
    if !empty(l:lines)
      call extend(l:all_lines, ['--- ' . l:file, ''])
      call extend(l:all_lines, l:lines)
      call add(l:all_lines, '')
    endif
  endfor
  
  " Render combined content
  call ghostgit#util#Render(l:all_lines)
  
  " Buffer configuration
  setlocal nomodifiable
  setlocal filetype=diff
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  
  let &local.statusline='%#StatusLine#[GhostGit]\ Staged\ Diff%='
  
  " Configure keyboard mappings
  nnoremap <silent><buffer> q :bd!<CR>
  nnoremap <silent><buffer> <C-c> :bd!<CR>
endfunction

" Compare two specific commits
function! ghostgit#diff#CompareCommits(commit1, commit2, ...) abort
  " Validate arguments
  if empty(a:commit1) || empty(a:commit2)
    call ghostgit#util#Error('Two commit hashes required for comparison')
    return
  endif
  
  " Get specific route if provided
  let l:path = get(a:000, 0, '')
  
  " Build comparison command
  let l:args = ['diff', a:commit1, a:commit2]
  
  if !empty(l:path)
    call add(l:args, '--')
    call add(l:args, l:path)
  endif
  
  " Run command
  let l:lines = ghostgit#core#Run(l:args)
  
  " Check results
  if empty(l:lines)
    call ghostgit#util#Info('No differences between ' . a:commit1 . ' and ' . a:commit2)
    return
  endif
  
  " Create buffer for comparison
  let l:bufname = 'diff/' . a:commit1 . '..' . a:commit2
  if !empty(l:path)
    let l:bufname .= '/' . l:path
  endif
  
  call ghostgit#util#OpenBuffer(l:bufname, 'botright')
  call ghostgit#util#Render(l:lines)
  
  " Buffer configuration
  setlocal nomodifiable
  setlocal filetype=diff
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  
  let &local.statusline='%#StatusLine#[GhostGit]\ Diff\ ' . a:commit1 . '..' . a:commit2 . '%='
  
  " Configure keyboard mappings
  nnoremap <silent><buffer> q :bd!<CR>
  nnoremap <silent><buffer> <C-c> :bd!<CR>
endfunction