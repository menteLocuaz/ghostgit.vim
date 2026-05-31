" ============================================================================
" ghostgit.vim - Event Handlers
" ============================================================================

" Initialize automatic event listeners
function! ghostgit#events#Init() abort
  if get(g:, 'ghostgit_disable_autorefresh', 0)
    return
  endif

  " Default events that trigger a refresh
  let l:events = get(g:, 'ghostgit_autorefresh_events', [
        \ 'BufWritePost', 
        \ 'FocusGained', 
        \ 'ShellCmdPost', 
        \ 'DirChanged'
        \ ])

  augroup GhostGitAutoRefresh
    autocmd!
    for l:event in l:events
      execute 'autocmd ' . l:event . ' * call s:OnFilesystemChange()'
    endfor
  augroup END
endfunction

" Handler for filesystem or environment changes
function! s:OnFilesystemChange() abort
  " Performance: Skip if the current buffer isn't in a Git repo (Fast Path)
  " This avoids overhead for non-git files.
  if empty(ghostgit#core#RepoRoot())
    return
  endif

  " Scalability: Iterate through active GhostGit components
  " We refresh any GhostGit buffer that is currently VISIBLE.
  for l:name in ['status', 'log', 'branch', 'diff']
    let l:bufname = 'ghostgit://' . l:name
    
    " Performance: Only refresh if the buffer exists AND is visible in a window.
    " This prevents background Git calls for hidden buffers.
    let l:bufnr = bufnr(l:bufname)
    if l:bufnr != -1 && bufwinid(l:bufnr) != -1
      try
        " Call the refresh function for the component
        " e.g., ghostgit#status#Refresh()
        let l:RefreshFunc = 'ghostgit#' . l:name . '#Refresh'
        if exists('*' . l:RefreshFunc)
          execute 'call ' . l:RefreshFunc . '()'
        endif
      catch
        call ghostgit#util#Warn('Failed to auto-refresh ' . l:name . ': ' . v:exception)
      endtry
    endif
  endfor
endfunction
