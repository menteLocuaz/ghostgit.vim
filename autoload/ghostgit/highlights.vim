" ============================================================================
" ghostgit.vim - Highlight Definitions
" ============================================================================

function! ghostgit#highlights#Init() abort
  " Core UI elements
  hi def link GhostGitHeader          Title
  hi def link GhostGitSectionHeader   Title
  hi def link GhostGitSeparator       Comment
  hi def link GhostGitFooter          Comment
  hi def link GhostGitSummary         Directory
  hi def link GhostGitLegend          Comment
  hi def link GhostGitInfoMessage     SpecialComment

  " Status indicators
  hi def link GhostGitStagedIndex     DiffAdd
  hi def link GhostGitUnstagedIndex   DiffChange
  hi def link GhostGitUntrackedIndex  NonText
  hi def link GhostGitConflictIndex   Error
  hi def link GhostGitRenameIndex     String
  hi def link GhostGitCopyIndex       String

  " Lines
  hi def link GhostGitStagedLine      DiffAdd
  hi def link GhostGitUnstagedLine    DiffChange
  hi def link GhostGitUntrackedLine   NonText
  hi def link GhostGitConflictLine    Error
  hi def link GhostGitRenameLine      String
  hi def link GhostGitCopyLine        String

  " Specific conflict groups
  hi def link GhostGitConflictDD      ErrorMsg
  hi def link GhostGitConflictAU      ErrorMsg
  hi def link GhostGitConflictUA      ErrorMsg
  hi def link GhostGitConflictDU      ErrorMsg

  " Branches
  hi def link GhostGitBranchCurrent   Special
  hi def link GhostGitBranchRemote    Comment

  " Commit info
  hi def link GhostGitCommitHash      Identifier
  hi def link GhostGitCommitRefs      Special
  hi def link GhostGitCommitAuthor    Constant
  hi def link GhostGitCommitDate      Comment

  " Custom colors for better clarity (based on terminal background)
  if &background == 'dark'
    hi GhostGitStagedIndex        ctermfg=green  guifg=#98c379
    hi GhostGitUnstagedIndex      ctermfg=yellow guifg=#e5c07b
    hi GhostGitUntrackedIndex     ctermfg=red    guifg=#e06c75
    hi GhostGitConflictIndex      ctermfg=white  ctermbg=red  guifg=#ffffff guibg=#be5046
  else
    hi GhostGitStagedIndex        ctermfg=green  guifg=#22863a
    hi GhostGitUnstagedIndex      ctermfg=darkyellow guifg=#b08800
    hi GhostGitUntrackedIndex     ctermfg=red    guifg=#cb2431
    hi GhostGitConflictIndex      ctermfg=white  ctermbg=red  guifg=#000000 guibg=#cb2431
  endif
endfunction
