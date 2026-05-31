" Verification script for ghostgit.vim improvements
set rtp^=.

let g:ghostgit_core_timeout = 5

function! Assert(cond, msg) abort
  if !a:cond
    echoerr "FAILED: " . a:msg
    call exit(1)
  endif
endfunction

try
  " Test RepoRoot
  let root = ghostgit#core#RepoRoot()
  call Assert(!empty(root), "RepoRoot should not be empty")
  echo "RepoRoot: " . root

  " Test CurrentBranch (should be master or main)
  let branch = ghostgit#core#CurrentBranch()
  call Assert(!empty(branch), "CurrentBranch should not be empty")
  echo "CurrentBranch: " . branch

  " Test Run
  let output = ghostgit#core#Run(['rev-parse', '--is-inside-work-tree'])
  call Assert(!empty(output) && output[0] == 'true', "Run should return correct output")
  echo "Run output: " . string(output)

  " Test caching
  let start_time = reltime()
  let branch2 = ghostgit#core#CurrentBranch()
  let elapsed = reltimefloat(reltime(start_time))
  call Assert(branch == branch2, "Cached branch should match")
  echo "Cached CurrentBranch lookup took: " . elapsed . "s"

  echo "Verification SUCCESS"
  qall!
catch
  echoerr "Verification ERROR: " . v:exception
  call exit(1)
endtry
