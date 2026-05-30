" ============================================================================
" ghostgit.vim - Entry Point
" ============================================================================
if exists('g:loaded_ghostgit') | finish | endif
let g:loaded_ghostgit = 1

let g:ghostgit_version = '0.1.0'

call ghostgit#state#Init()

command! GStatus call ghostgit#status#Open()
command! GLog   call ghostgit#log#Open()
command! -nargs=* -complete=customlist,ghostgit#core#Complete Git call ghostgit#core#Execute(<q-args>)
command! -nargs=* -complete=customlist,ghostgit#core#Complete G   call ghostgit#core#Execute(<q-args>)
