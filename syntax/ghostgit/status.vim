" ============================================================================
" ghostgit.vim - Status Buffer Syntax Highlighting
" ============================================================================

if exists("b:current_syntax")
  finish
endif

" Section Headers
syn match ghostgitSectionHeader '^\(Changes to be committed:\|Changes not staged for commit:\|Untracked files:\)$'

" Staged files
syn match ghostgitStagedIndex '^  [MARC] ' containedin=ghostgitStagedLine
syn match ghostgitStagedLine '^  [MARC] .*' contains=ghostgitStagedIndex

" Unstaged files
syn match ghostgitUnstagedIndex '^  [ MADRCU] ' containedin=ghostgitUnstagedLine
syn match ghostgitUnstagedLine '^  [ MADRCU] .*' contains=ghostgitUnstagedIndex

" Untracked files
syn match ghostgitUntracked '^  ?? .*'

" Rename or Copy (R/C)
syn match ghostgitRename '^  R .*'
syn match ghostgitCopy '^  C .*'

" Conflicted files (UU)
syn match ghostgitConflict '^  UU .*'

" Header/Footer
syn match ghostgitHeader '^  GhostGit.*$'
syn match ghostgitFooter '^Help:.*$'

" Highlight links
hi def link ghostgitSectionHeader Title
hi def link ghostgitHeader       Title
hi def link ghostgitFooter       Comment

hi def link ghostgitStagedIndex    DiffAdd
hi def link ghostgitUnstagedIndex  DiffChange
hi def link ghostgitUntracked      NonText
hi def link ghostgitRename         String
hi def link ghostgitCopy           String
hi def link ghostgitConflict       Error

let b:current_syntax = "ghostgit_status"
