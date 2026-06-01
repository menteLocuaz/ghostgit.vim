" ============================================================================
" ghostgit.vim - Commit Interface
" ============================================================================

" Open the commit message buffer
function! ghostgit#commit#Open(...) abort
  " Verify that we are in a Git repository
  let l:repo_root = ghostgit#core#RepoRoot()
  if empty(l:repo_root)
    call ghostgit#util#Error('Not in a Git repository')
    return
  endif

  " Obtain additional options if provided
  let l:opts = get(a:000, 0, '')
  let l:repo_root = ghostgit#core#RepoRoot()
  
  " Use git-path to handle submodules and worktrees correctly
  let l:git_path = ghostgit#core#Run(['rev-parse', '--git-path', 'COMMIT_EDITMSG'], l:repo_root)
  if empty(l:git_path)
    call ghostgit#util#Error('Could not find .git path')
    return
  endif
  let l:commit_editmsg = l:git_path[0]
  
  " Open the file in a new split at the bottom
  try
    execute 'botright split ' . fnameescape(l:commit_editmsg)
  catch
    call ghostgit#util#Error('Failed to open commit message buffer')
    return
  endtry
  
  " Configure buffer options
  setlocal buftype=acwrite
  setlocal bufhidden=delete
  setlocal filetype=gitcommit
  setlocal nomodeline
  
  " Save options for when the buffer closes
  let b:ghostgit_commit_opts = l:opts
  let b:ghostgit_repo_root = l:repo_root
  
  " Define mappings to finalize the commit or cancel
  nnoremap <silent><buffer> <C-c><C-c> :call ghostgit#commit#Finish()<CR>
  nnoremap <silent><buffer> <C-c><C-k> :call ghostgit#commit#Cancel()<CR>
  nnoremap <silent><buffer> q :call ghostgit#commit#Cancel()<CR>
  
  " Configure autocmd to clean up if the user closes the buffer without committing.
  augroup GhostGitCommit
    autocmd! BufUnload <buffer> call ghostgit#commit#Cleanup()
  augroup END
  
  " Show instructions to the user
  call ghostgit#util#Info('Enter commit message and press <C-c><C-c> to commit or <C-c><C-k> to cancel')
  
  " Insert message template if one exists
  if line('$') == 1 && getline(1) == ''
    call ghostgit#commit#InsertTemplate()
  endif
endfunction

" Insert commit message template
function! ghostgit#commit#InsertTemplate() abort
  " Agregar líneas comentadas con instrucciones
  call append(0, '# Please enter the commit message for your changes.')
  call append(1, '# Lines starting with ''#'' will be ignored, and an empty message aborts the commit.')
  call append(2, '#')
  
  " Attempt to obtain statistical diff for reference
  try
    let l:stat = ghostgit#core#Run(['diff', '--stat'])
    if !empty(l:stat)
      call append(3, '# Changes to be committed:')
      for l:line in l:stat
        call append(line('.'), '#   ' . l:line)
      endfor
    endif
  catch
    " Silently ignore if it fails
  endtry
  
  " Move cursor to the beginning of the buffer to write the message
  normal! gg
endfunction

" End the commit process
function! ghostgit#commit#Finish() abort
  " Verify that the commit message is not empty (ignoring comments)
  let l:message_lines = []
  for l:line in getline(1, '$')
    if l:line !~# '^\s*#' && l:line !~# '^\s*$'
      call add(l:message_lines, l:line)
    endif
  endfor
  
  " If there is no message, abort
  if empty(l:message_lines)
    call ghostgit#util#Warn('Empty commit message. Commit aborted.')
    call ghostgit#commit#Cancel()
    return
  endif
  
  " Save the current buffer
  silent! write
  
  " Get stored options
  let l:opts = get(b:, 'ghostgit_commit_opts', '')
  let l:repo_root = get(b:, 'ghostgit_repo_root', '')
  let l:msg_file = expand('%:p')
  
  " Remove autocmd before closing the buffer
  augroup GhostGitCommit
    autocmd! BufUnload <buffer>
  augroup END
  
  " Close the commit buffer
  bd!
  
  " Prepare arguments for git commit
  let l:args = ['commit', '-F', l:msg_file]
  if !empty(l:opts)
    for l:opt in split(l:opts, '\s\+')
      call add(l:args, l:opt)
    endfor
  endif
  
  " Run git commit asynchronously
  call ghostgit#core#Run(l:args, l:repo_root, {
        \ 'on_success': {lines -> s:OnCommitSuccess(lines)},
        \ 'on_failure': {err -> ghostgit#util#Error('Failed to commit: ' . join(err, "\n"))}
        \ })
endfunction

" Callback for commit success
function! s:OnCommitSuccess(output) abort
  if !empty(a:output)
    call ghostgit#util#Info('Changes committed successfully: ' . get(a:output, 0, ''))
  else
    call ghostgit#util#Info('Commit completed')
  endif
  
  " Refresh status if open
  call ghostgit#commit#RefreshStatus()
endfunction

" Cancel the commit process
function! ghostgit#commit#Cancel() abort
  " Remove autocmd before closing the buffer
  augroup GhostGitCommit
    autocmd! BufUnload <buffer>
  augroup END
  
  " Close the buffer without saving.
  bd!
  
  call ghostgit#util#Info('Commit canceled')
endfunction

" Clean up resources when the buffer closes
function! ghostgit#commit#Cleanup() abort
  " Remove autocmd group
  augroup GhostGitCommit
    autocmd! BufUnload <buffer>
  augroup END
endfunction

" Refresh the status view if it is open
function! ghostgit#commit#RefreshStatus() abort
  " Search for ghostgit state buffer
  let l:status_buf = bufnr('ghostgit://status')
  if l:status_buf != -1
    try
      call ghostgit#status#Refresh()
    catch
      " Silently ignore errors when refreshing
    endtry
  endif
endfunction