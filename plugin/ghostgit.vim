" plugin/ghostgit.vim
if exists('g:loaded_ghostgit') | finish | endif
let g:loaded_ghostgit = 1

command! -nargs=* GG call ghostgit#status#Open()
command! -nargs=* Git call ghostgit#core#RunGit(<q-args>)
command! GBlame     call ghostgit#blame#Open()
command! GDiff      call ghostgit#diff#Open()
command! GLog       call ghostgit#log#Open()
