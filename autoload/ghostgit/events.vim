" ============================================================================
" ghostgit.vim - Event Handlers
" ============================================================================

" Global variables for configurations
if !exists('g:ghostgit_disable_autorefresh')
  let g:ghostgit_disable_autorefresh = 0
endif

if !exists('g:ghostgit_autorefresh_events')
  let g:ghostgit_autorefresh_events = [
        \ 'BufWritePost', 
        \ 'FocusGained', 
        \ 'ShellCmdPost', 
        \ 'DirChanged',
        \ 'VimResume'
        \ ]
endif

if !exists('g:ghostgit_refresh_throttle_ms')
  let g:ghostgit_refresh_throttle_ms = 1000
endif

if !exists('g:ghostgit_refresh_components')
  let g:ghostgit_refresh_components = ['status', 'log', 'branch', 'diff']
endif

" Initialize automatic event listeners
function! ghostgit#events#Init() abort
  " Check if automatic updates are disabled
  if g:ghostgit_disable_autorefreshDebug
    return
  endif

  " Validate that the events are a list
  if type(g:ghostgit_autorefresh_events) != v:t_list
    call ghostgit#util#Warn('Invalid autorefresh events configuration')
    let l:events = ['BufWritePost', 'FocusGained', 'ShellCmdPost', 'DirChanged']
  else
    let l:events = g:ghostgit_autorefresh_events
  endif

  " Clear existing autocmds group
  augroup GhostGitAutoRefresh
    autocmd!
    
    " Log events for automatic updates
    for l:event in l:events
      try
        execute 'autocmd ' . l:event . ' * call ghostgit#events#OnFilesystemChange()'
      catch
        call ghostgit#util#Warn('Failed to register event: ' . l:event)
      endtry
    endfor
    
    " Register special event for directory change
    autocmd DirChanged * call ghostgit#events#OnDirChange()
    
    " Log event for when Vim regains focus (for GUIs)
    if has('gui_running')
      autocmd FocusGained * call ghostgit#events#OnFocusGained()
    endif
  augroup END
  
  " Record event for cleaning upon departure
  augroup GhostGitCleanup
    autocmd!
    autocmd VimLeavePre * call ghostgit#events#OnExit()
  augroup END
endfunction

" Handler for changes to the file system or environment
let s:last_refresh_time = 0
let s:is_refreshing = 0

function! ghostgit#events#OnFilesystemChange() abort
  " Avoid recursion during the update
  if s:is_refreshing
    return
  endif

  " Flow control to prevent overload during rapid changeovers
  let l:now = reltimefloat(reltime())
  if (l:now - s:last_refresh_time) < (g:ghostgit_refresh_throttle_ms / 1000.0)
    return
  endif
  
  " Mark that we are updating
  let s:is_refreshing = 1
  let s:last_refresh_time = l:now

  try
    " Fast performance path: Skip if current directory is not a Git repository
    " This avoids overloading non-Git files.
    if !ghostgit#core#IsRepo()
      return
    endif

    " Scalability: Iterating through active GhostGit components
    " We only update GhostGit buffers that are currently VISIBLE.
    let l:refreshed_count = 0
    
    " Validate components to be updated
    if type(g:ghostgit_refresh_components) != v:t_list
      let l:components = ['status', 'log', 'branch', 'diff']
    else
      let l:components = g:ghostgit_refresh_components
    endif

    for l:name in l:components
      try
        " Only continue if the component is not empty.
        if empty(l:name)
          continue
        endif
        
        let l:bufname = 'ghostgit://' . l:name
        
        " Performance: Only update if the buffer exists AND is visible in a window.
        " This prevents background Git calls for hidden buffers.
        let l:bufnr = bufnr(l:bufname)
        if l:bufnr != -1 && bufwinid(l:bufnr) != -1
          " Verify that the update function exists
          let l:RefreshFunc = 'ghostgit#' . l:name . '#Refresh'
          if exists('*' . l:RefreshFunc)
            execute 'call ' . l:RefreshFunc . '()'
            let l:refreshed_count += 1
          endif
        endif
      catch
        " Log error but continue with other components
        call ghostgit#util#Warn('Failed to auto-refresh ' . l:name . ': ' . v:exception)
      endtry
    endfor
    
    " If components were updated, log it.
    if l:refreshed_count > 0
      call ghostgit#util#Debug('Auto-refreshed ' . l:refreshed_count . ' components')
    endif
  finally
    " Ensure that the update status is restored
    let s:is_refreshing = 0
  endtry
endfunction

" Special handler for directory change
function! ghostgit#events#OnDirChange() abort
  " Reset the last update time to allow immediate updates
  let s:last_refresh_time = 0
  
  " Check if the new directory is a Git repository
  if ghostgit#core#IsRepo()
    call ghostgit#util#Info('Entered Git repository: ' . getcwd())
    " Force immediate update
    call ghostgit#events#OnFilesystemChange()
  endif
endfunction

" Handler for when Vim regains focus
function! ghostgit#events#OnFocusGained() abort
  " Only update if at least 5 seconds have passed since the last update
  let l:now = reltimefloat(reltime())
  if (l:now - s:last_refresh_time) > 5.0
    " Restart throttle for immediate update
    let s:last_refresh_time = 0
    call ghostgit#events#OnFilesystemChange()
  endif
endfunction

" Handler for cleaning upon exiting Vim
function! ghostgit#events#OnExit() abort
  " Clean up resources if necessary
  try
    " Close open GhostGit buffers
    for l:name in ['status', 'log', 'branch', 'diff']
      let l:bufname = 'ghostgit://' . l:name
      let l:bufnr = bufnr(l:bufname)
      if l:bufnr != -1
        execute 'bwipeout! ' . l:bufnr
      endif
    endfor
  catch
    " Silently ignore mistakes upon exiting
  endtry
endfunction

" Force manual update of all visible components
function! ghostgit#events#ForceRefresh() abort
  " Restart throttle to allow immediate update
  let s:last_refresh_time = 0
  call ghostgit#events#OnFilesystemChange()
endfunction

" Temporarily disable automatic updates
function! ghostgit#events#DisableAutoRefresh() abort
  let g:ghostgit_disable_autorefresh = 1
  
  " Remove autocmds
  augroup GhostGitAutoRefresh
    autocmd!
  augroup END
  
  call ghostgit#util#Info('Auto-refresh disabled')
endfunction

" Enable automatic updates
function! ghostgit#events#EnableAutoRefresh() abort
  let g:ghostgit_disable_autorefresh = 0
  call ghostgit#events#Init()
  call ghostgit#util#Info('Auto-refresh enabled')
endfunction

" Check automatic update status
function! ghostgit#events#CheckAutoRefreshStatus() abort
  if g:ghostgit_disable_autorefresh
    call ghostgit#util#Info('Auto-refresh is currently DISABLED')
  else
    call ghostgit#util#Info('Auto-refresh is currently ENABLED')
  endif
endfunction

" Commands for event control
command! GRefresh call ghostgit#events#ForceRefresh()
command! GAutoRefreshDisable call ghostgit#events#DisableAutoRefresh()
command! GAutoRefreshEnable call ghostgit#events#EnableAutoRefresh()
command! GAutoRefreshStatus call ghostgit#events#CheckAutoRefreshStatus()