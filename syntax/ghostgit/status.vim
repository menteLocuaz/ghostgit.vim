" ============================================================================
" ghostgit - Status Buffer Syntax Highlight
" ============================================================================

if exists("b:current_syntax")
  finish
endif

syn match ghostgitHeader '^GhostGit.*$'
syn match ghostgitBranch '^GhostGit — \zs.*$'
syn match ghostgitStaged '^[MARC] .*'
syn match ghostgitUnstaged '^[ MADRCU?!]\{2} .*' contains=ghostgitStaged
syn match ghostgitFooter '^Shortcuts:.*$'

hi def link ghostgitHeader Title
hi def link ghostgitBranch Constant
hi def link ghostgitStaged DiffAdd
hi def link ghostgitUnstaged DiffChange
hi def link ghostgitFooter Comment

let b:current_syntax = "ghostgit_status"
