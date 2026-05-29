" ============================================================================
" ghostgit.vim - Status Buffer Syntax Highlighting
" ============================================================================

" Avoid loading the script if it is already loaded.
if exists("b:current_syntax")
  finish
endif

" Verify that we are in a GhostGit buffer
if !exists("b:ghostgit_buffer")
  let b:ghostgit_buffer = 1
endif

" Header sections
syn match ghostgitSectionHeader '^\(Changes to be committed:\|Changes not staged for commit:\|Untracked files:\|Conflicting files:\)$'
syn match ghostgitSectionHeader '^\(Local branches:\|Remote branches:\|Commit History:\)$'

" Files in staging (ready for commit)
syn match ghostgitStagedIndex '^  [MARC] ' containedin=ghostgitStagedLine
syn match ghostgitStagedLine '^  [MARC] .*' contains=ghostgitStagedIndex

" Files modified but not in staging
syn match ghostgitUnstagedIndex '^  [ MADRCU] ' containedin=ghostgitUnstagedLine
syn match ghostgitUnstagedLine '^  [ MADRCU] .*' contains=ghostgitUnstagedIndex

" Untracked files
syn match ghostgitUntrackedIndex '^  \?? ' containedin=ghostgitUntrackedLine
syn match ghostgitUntrackedLine '^  \?? .*' contains=ghostgitUntrackedIndex

" Conflicting files
syn match ghostgitConflictIndex '^  [UD] ' containedin=ghostgitConflictLine
syn match ghostgitConflictLine '^  [UD] .*' contains=ghostgitConflictIndex
syn match ghostgitConflictDD '^  DD .*'
syn match ghostgitConflictAU '^  AU .*'
syn match ghostgitConflictUA '^  UA .*'
syn match ghostgitConflictDU '^  DU .*'

" Renamed or copied files
syn match ghostgitRenameIndex '^  R ' containedin=ghostgitRenameLine
syn match ghostgitRenameLine '^  R .*' contains=ghostgitRenameIndex
syn match ghostgitCopyIndex '^  C ' containedin=ghostgitCopyLine
syn match ghostgitCopyLine '^  C .*' contains=ghostgitCopyIndex

" Branch information
syn match ghostgitBranchCurrent '^\* .*' 
syn match ghostgitBranchRemote '^  origin/.*'

" Separators and special lines
syn match ghostgitSeparator '^  \%(─\+\|\=\+\)$'
syn match ghostgitEmptyLine '^$'

" Header and footer
syn match ghostgitHeader '^  GhostGit.*$'
syn match ghostgitFooter '^Help:.*$'
syn match ghostgitSummary '^Summary:.*$'
syn match ghostgitLegend '^Legend:.*$'

" Informational messages
syn match ghostgitInfoMessage '^\(Summary\|Legend\):.*$'

" Commit code
syn match ghostgitCommitHash '^commit [0-9a-f]\{4,}$'
syn match ghostgitCommitRefs '^Refs:.*$'
syn match ghostgitCommitAuthor '^Author:.*$'
syn match ghostgitCommitDate '^Date:.*$'

" Status symbols
syn keyword ghostgitStatusSymbol Modified Added Deleted Renamed Copied Untracked contained
syn match ghostgitStatusLine '^  [MADRCU?!] .*' contains=ghostgitStatusSymbol

" Highlighting for different parts of the buffer
hi def link ghostgitSectionHeader       Title
hi def link ghostgitHeader             Title
hi def link ghostgitFooter             Comment
hi def link ghostgitSummary            Directory
hi def link ghostgitLegend             Comment
hi def link ghostgitInfoMessage        SpecialComment

" Highlighted for status codes
hi def link ghostgitStagedIndex        DiffAdd
hi def link ghostgitUnstagedIndex      DiffChange
hi def link ghostgitUntrackedIndex     NonText
hi def link ghostgitConflictIndex      Error
hi def link ghostgitRenameIndex        String
hi def link ghostgitCopyIndex          String

" Highlighting for full lines
hi def link ghostgitStagedLine         DiffAdd
hi def link ghostgitUnstagedLine       DiffChange
hi def link ghostgitUntrackedLine      NonText
hi def link ghostgitConflictLine       Error
hi def link ghostgitRenameLine         String
hi def link ghostgitCopyLine           String

" Specific highlighting for conflicts
hi def link ghostgitConflictDD         ErrorMsg
hi def link ghostgitConflictAU         ErrorMsg
hi def link ghostgitConflictUA         ErrorMsg
hi def link ghostgitConflictDU         ErrorMsg

" Highlighting for branches
hi def link ghostgitBranchCurrent      Special
hi def link ghostgitBranchRemote       Comment

" Highlighting for visual elements
hi def link ghostgitSeparator          Comment
hi def link ghostgitEmptyLine          NONE

" Highlighted for commit information
hi def link ghostgitCommitHash         Identifier
hi def link ghostgitCommitRefs         Special
hi def link ghostgitCommitAuthor       Constant
hi def link ghostgitCommitDate         Comment

" Highlighted for status symbols
hi def link ghostgitStatusSymbol       Keyword

" Custom colors for greater clarity (if the color scheme allows it)
if &background == 'dark'
  hi ghostgitStagedIndex        ctermfg=green  guifg=#98c379
  hi ghostgitUnstagedIndex      ctermfg=yellow guifg=#e5c07b
  hi ghostgitUntrackedIndex     ctermfg=red    guifg=#e06c75
  hi ghostgitConflictIndex      ctermfg=white  ctermbg=red  guifg=#ffffff guibg=#be5046
else
  hi ghostgitStagedIndex        ctermfg=green  guifg=#22863a
  hi ghostgitUnstagedIndex      ctermfg=darkyellow guifg=#b08800
  hi ghostgitUntrackedIndex     ctermfg=red    guifg=#cb2431
  hi ghostgitConflictIndex      ctermfg=white  ctermbg=red  guifg=#000000 guibg=#cb2431
endif

" Define the current syntax
let b:current_syntax = "ghostgit_status"

" Function to reload syntax if necessary
function! ghostgit#syntax#Reload() abort
  if exists("b:current_syntax")
    unlet b:current_syntax
  endif
  runtime syntax/ghostgit_status.vim
endfunction