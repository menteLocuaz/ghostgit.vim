if exists("b:current_syntax")
  finish
endif

" Initialize highlight groups
call ghostgit#highlights#Init()

" Matches the indent added in render#Log
syn match ghostgitLogIndent '^  ' contained

syn match ghostgitLogGraph  '^  [*|\\\/ ]\+' contains=ghostgitLogIndent
syn match ghostgitLogHash   '\x\{7,\}'
syn match ghostgitLogHeader '^  GhostGit — Log'
syn match ghostgitLogFooter '^Help:.*$'

" Decorations like (HEAD -> master, origin/master)
syn region ghostgitLogRef start='(' end=')' containedin=ghostgitLogLine oneline
syn match ghostgitLogLine '^  .*' contains=ghostgitLogGraph,ghostgitLogHash,ghostgitLogRef

hi def link ghostgitLogHash   GhostGitCommitHash
hi def link ghostgitLogGraph  Comment
hi def link ghostgitLogHeader Title
hi def link ghostgitLogFooter Comment
hi def link ghostgitLogRef    GhostGitLogRef

let b:current_syntax = "ghostgit_log"
