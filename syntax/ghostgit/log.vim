if exists("b:current_syntax")
  finish
endif

syn match ghostgitLogHash   '\x\{7,\}'
syn match ghostgitLogGraph  '^  [*|\\\/ ]\+'
syn match ghostgitLogHeader '^  GhostGit.*$'
syn match ghostgitLogFooter '^Help:.*$'

hi def link ghostgitLogHash   Identifier
hi def link ghostgitLogGraph  Comment
hi def link ghostgitLogHeader Title
hi def link ghostgitLogFooter Comment

let b:current_syntax = "ghostgit_log"
