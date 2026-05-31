" ============================================================================
" ghostgit.vim - Diff Preview Buffer
" ============================================================================

" Helper to build diff command
function! s:BuildDiffCmd(file, extra_args) abort
  let l:args = ['git', 'diff']
  
  if !empty(a:extra_args)
    if type(a:extra_args) == v:t_string
      call extend(l:args, split(a:extra_args, '\s\+'))
    else
      call add(l:args, a:extra_args)
    endif
  endif

  if !empty(a:file)
    call extend(l:args, ['--', a:file])
  endif
  
  return l:args
endfunction

" Open diff window for a file
function! ghostgit#diff#Open(file, ...) abort
  if empty(a:file)
    call ghostgit#util#Error('No file specified for diff')
    return
  endif

  let l:extra_args = get(a:000, 0, '')
  let l:repo_root = ghostgit#core#RepoRoot()
  let l:bufname = 'diff/' . a:file
  
  " Create or open diff buffer immediately
  call ghostgit#util#OpenBuffer(l:bufname, 'botright')
  setlocal filetype=diff
  let l:bufnr = bufnr('%')
  call ghostgit#util#Render(['  Loading diff for ' . a:file . '...'])

  " Set buffer title
  let &l:statusline='%#StatusLine#[GhostGit]\ Diff\ ' . a:file . '%='
  
  " Save state for refresh
  call ghostgit#state#SetBufferData(l:bufname, {
        \ 'file': a:file,
        \ 'extra_args': l:extra_args
        \ })

  " Run async job
  call ghostgit#job#Schedule('diff:' . a:file, s:BuildDiffCmd(a:file, l:extra_args), {
        \ 'bufnr': l:bufnr,
        \ 'cwd': l:repo_root,
        \ 'on_success': {lines -> ghostgit#util#RenderToBuffer(l:bufnr, lines)},
        \ 'on_failure': {err -> ghostgit#util#Error('Diff error for ' . a:file . ': ' . join(err, ' '))}
        \ })
endfunction

" Refresh current diff content
function! ghostgit#diff#Refresh() abort
  let l:bufnr = bufnr('%')
  let l:bufname = bufname(l:bufnr)
  
  if l:bufname !~ '^ghostgit://diff/'
    call ghostgit#util#Error('Not in a diff buffer')
    return
  endif
  
  let l:data = ghostgit#state#GetBufferData(substitute(l:bufname, '^ghostgit://', '', ''))
  let l:file = get(l:data, 'file', '')
  let l:extra_args = get(l:data, 'extra_args', '')
  let l:repo_root = ghostgit#core#RepoRoot()

  call ghostgit#util#Info('Refreshing diff...')
  
  call ghostgit#job#Schedule('diff:' . l:file, s:BuildDiffCmd(l:file, l:extra_args), {
        \ 'bufnr': l:bufnr,
        \ 'cwd': l:repo_root,
        \ 'on_success': {lines -> ghostgit#util#RenderToBuffer(l:bufnr, lines)},
        \ 'on_failure': {err -> ghostgit#util#Error('Failed to refresh diff')}
        \ })
endfunction

" Open diff of all files in staging
function! ghostgit#diff#OpenStaged() abort
  " Verify that we are in a repository
  if !ghostgit#core#IsRepo()
    call ghostgit#util#Error('Not in a git repository')
    return
  endif

  let l:repo_root = ghostgit#core#RepoRoot()
  if empty(l:repo_root)
    return
  endif

  " Get files in staging
  let l:staged_files = ghostgit#git#GetStagedFiles(l:repo_root)
  
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
  
  let &l:statusline='%#StatusLine#[GhostGit]\ Staged\ Diff%='
  
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
  
  " Create buffer for comparison (use short hashes)
  let l:bufname = 'diff/' . a:commit1[:6] . '..' . a:commit2[:6]
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
  
  let &l:statusline='%#StatusLine#[GhostGit]\ Diff\ ' . a:commit1 . '..' . a:commit2 . '%='
  
  " Configure keyboard mappings
  nnoremap <silent><buffer> q :bd!<CR>
  nnoremap <silent><buffer> <C-c> :bd!<CR>
endfunction