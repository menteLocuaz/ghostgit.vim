" ============================================================================
" ghostgit.vim - Status Buffer Syntax Highlighting
" ============================================================================

if exists("b:current_syntax")
  finish
endif

" Initialize highlight groups
call ghostgit#highlights#Init()

" Header sections
syn match GhostGitSectionHeader '^\(Changes to be committed:\|Changes not staged for commit:\|Untracked files:\|Conflicting files:\)$'
syn match GhostGitSectionHeader '^\(Local branches:\|Remote branches:\|Commit History:\)$'

" Files in staging (ready for commit)
" Using a more precise match for the status character
syn match GhostGitStagedIndex '^  [MADRC] ' containedin=GhostGitStagedLine
syn match GhostGitStagedLine '^  [MADRC] .*' contains=GhostGitStagedIndex

" Files modified but not in staging
syn match GhostGitUnstagedIndex '^  [MADRC] ' containedin=GhostGitUnstagedLine
syn match GhostGitUnstagedLine '^  [MADRC] .*' contains=GhostGitUnstagedIndex

" Untracked files
syn match GhostGitUntrackedIndex '^  ?? ' containedin=GhostGitUntrackedLine
syn match GhostGitUntrackedLine '^  ?? .*' contains=GhostGitUntrackedIndex

" Conflicting files
" Matches symbols like '  UU ', '  AA ', or the simplified '  ! '
syn match GhostGitConflictIndex '^  \(!\|[UDA]\{2\}\) ' containedin=GhostGitConflictLine
syn match GhostGitConflictLine '^  \(!\|[UDA]\{2\}\) .*' contains=GhostGitConflictIndex

" Branch information
syn match GhostGitBranchCurrent '^\s*\* .*' 
syn match GhostGitBranchRemote '^\s*origin/.*'
syn match GhostGitHeader '^  GhostGit — .*' contains=GhostGitBranchCurrent

" UI Elements
syn match GhostGitSeparator '^  [─=]\+$'
syn match GhostGitFooter '^Commands:.*$'
syn match GhostGitSummary '^Summary:.*$'
syn match GhostGitLegend '^Legend:.*$'

" Highlights linking
hi def link GhostGitStagedIndex     GhostGitStagedIndex
hi def link GhostGitUnstagedIndex   GhostGitUnstagedIndex
hi def link GhostGitUntrackedIndex  GhostGitUntrackedIndex
hi def link GhostGitConflictIndex   GhostGitConflictIndex
hi def link GhostGitSectionHeader   GhostGitSectionHeader
hi def link GhostGitHeader          GhostGitHeader
hi def link GhostGitFooter          GhostGitFooter
hi def link GhostGitSummary         GhostGitSummary
hi def link GhostGitLegend          GhostGitLegend

let b:current_syntax = "ghostgit_status"
