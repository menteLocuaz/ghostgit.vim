" ============================================================================
" ghostgit.vim - Highlight Definitions
" ============================================================================

function! ghostgit#highlights#Init() abort
  " Core UI elements
  hi def link GhostGitHeader          Title
  hi def link GhostGitSectionHeader   Statement
  hi def link GhostGitSeparator       Comment
  hi def link GhostGitFooter          Comment
  hi def link GhostGitSummary         Directory
  hi def link GhostGitLegend          NonText
  hi def link GhostGitInfoMessage     SpecialComment

  " Status indicators (Mapped to standard Git types if possible)
  hi def link GhostGitStagedIndex     Identifier
  hi def link GhostGitUnstagedIndex   PreProc
  hi def link GhostGitUntrackedIndex  Comment
  hi def link GhostGitConflictIndex   ErrorMsg
  
  " Lines
  hi def link GhostGitStagedLine      None
  hi def link GhostGitUnstagedLine    None
  hi def link GhostGitUntrackedLine   Comment
  hi def link GhostGitConflictLine    Error

  " Specific conflict groups
  hi def link GhostGitConflictDD      ErrorMsg
  hi def link GhostGitConflictAU      ErrorMsg
  hi def link GhostGitConflictUA      ErrorMsg
  hi def link GhostGitConflictDU      ErrorMsg

  " Branches
  hi def link GhostGitBranchCurrent   Type
  hi def link GhostGitBranchRemote    Comment

  " Commit info
  hi def link GhostGitCommitHash      Number
  hi def link GhostGitCommitRefs      Special
  hi def link GhostGitLogRef          Special
  hi def link GhostGitCommitAuthor    Constant
  hi def link GhostGitCommitDate      Comment

  " High-visibility overrides for common Git states
  " Green for staged, Yellow/Orange for modified, Red for untracked/conflict
  if &background == 'dark'
    hi GhostGitStagedIndex        guifg=#98c379 ctermfg=114
    hi GhostGitUnstagedIndex      guifg=#e5c07b ctermfg=180
    hi GhostGitUntrackedIndex     guifg=#abb2bf ctermfg=249
    hi GhostGitConflictIndex      guifg=#e06c75 ctermfg=168
  else
    hi GhostGitStagedIndex        guifg=#22863a ctermfg=28
    hi GhostGitUnstagedIndex      guifg=#b08800 ctermfg=136
    hi GhostGitUntrackedIndex     guifg=#6a737d ctermfg=244
    hi GhostGitConflictIndex      guifg=#cb2431 ctermfg=160
  endif
endfunction
