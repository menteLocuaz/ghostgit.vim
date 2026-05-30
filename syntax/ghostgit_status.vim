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
syn match GhostGitStagedIndex '^  [MARC] ' containedin=GhostGitStagedLine
syn match GhostGitStagedLine '^  [MARC] .*' contains=GhostGitStagedIndex

" Files modified but not in staging
syn match GhostGitUnstagedIndex '^  [ MADRCU] ' containedin=GhostGitUnstagedLine
syn match GhostGitUnstagedLine '^  [ MADRCU] .*' contains=GhostGitUnstagedIndex

" Untracked files
syn match GhostGitUntrackedIndex '^  \?? ' containedin=GhostGitUntrackedLine
syn match GhostGitUntrackedLine '^  \?? .*' contains=GhostGitUntrackedIndex

" Conflicting files
syn match GhostGitConflictIndex '^  [UD] ' containedin=GhostGitConflictLine
syn match GhostGitConflictLine '^  [UD] .*' contains=GhostGitConflictIndex
syn match GhostGitConflictDD '^  DD .*'
syn match GhostGitConflictAU '^  AU .*'
syn match GhostGitConflictUA '^  UA .*'
syn match GhostGitConflictDU '^  DU .*'

" Renamed or copied files
syn match GhostGitRenameIndex '^  R ' containedin=GhostGitRenameLine
syn match GhostGitRenameLine '^  R .*' contains=GhostGitRenameIndex
syn match GhostGitCopyIndex '^  C ' containedin=GhostGitCopyLine
syn match GhostGitCopyLine '^  C .*' contains=GhostGitCopyIndex

" Branch information
syn match GhostGitBranchCurrent '^\* .*' 
syn match GhostGitBranchRemote '^  origin/.*'

" Separators and special lines
syn match GhostGitSeparator '^  \%(─\+\|\=\+\)$'

" Header and footer
syn match GhostGitHeader '^  GhostGit.*$'
syn match GhostGitFooter '^Help:.*$'
syn match GhostGitSummary '^Summary:.*$'
syn match GhostGitLegend '^Legend:.*$'

" Informational messages
syn match GhostGitInfoMessage '^\(Summary\|Legend\):.*$'

" Link to standardized groups defined in highlights.vim
hi def link GhostGitConflictDD GhostGitConflictIndex
hi def link GhostGitConflictAU GhostGitConflictIndex
hi def link GhostGitConflictUA GhostGitConflictIndex
hi def link GhostGitConflictDU GhostGitConflictIndex

let b:current_syntax = "ghostgit_status"
