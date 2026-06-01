" ============================================================================
" ghostgit.vim - Entry Point
" ============================================================================
if exists('g:loaded_ghostgit') | finish | endif
let g:loaded_ghostgit = 1

let g:ghostgit_version = '0.1.0'

call ghostgit#state#Init()
call ghostgit#events#Init()

command! GStatus call ghostgit#status#Open()
command! GLog    call ghostgit#log#Open()
command! GBlame  call ghostgit#blame#Open()
command! -nargs=? GCommit call ghostgit#commit#Open(<q-args>)
command! -nargs=? GDiff   call ghostgit#diff#Open(expand('%'), <q-args>)
command! -range -nargs=? GBrowse call ghostgit#remote#Browse(<line1>, <line2>, <q-args>)
command! -nargs=? GFile      call ghostgit#remote#BrowseFile(<f-args>)
command! GRemotes   call ghostgit#remote#Show()
command! GRefresh   call ghostgit#events#ForceRefresh()
command! GAutoRefreshDisable call ghostgit#events#DisableAutoRefresh()
command! GAutoRefreshEnable  call ghostgit#events#EnableAutoRefresh()
command! GAutoRefreshStatus  call ghostgit#events#CheckAutoRefreshStatus()

command! -nargs=* -complete=customlist,ghostgit#complete#Complete Git call ghostgit#core#Execute(<q-args>)
command! -nargs=* -complete=customlist,ghostgit#complete#Complete G   call ghostgit#core#Execute(<q-args>)
