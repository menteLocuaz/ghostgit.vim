if exists("b:current_syntax")
  finish
endif

" Matches the indent added in render#Log
syn match ghostgitLogIndent '^  ' contained

syn match ghostgitLogGraph  '^  [*|\\\/ ]\+' contains=ghostgitLogIndent
syn match ghostgitLogHash   '\x\{7,\}'
syn match ghostgitLogHeader '^  GhostGit — Log'
syn match ghostgitLogFooter '^Help:.*$'

hi def link ghostgitLogHash   Identifier
hi def link ghostgitLogGraph  Comment
hi def link ghostgitLogHeader Title
hi def link ghostgitLogFooter Comment

let b:current_syntax = "ghostgit_log"
