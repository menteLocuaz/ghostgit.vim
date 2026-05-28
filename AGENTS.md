# ghostgit.vim — AGENTS.md

## State

Early-stage Vim plugin. 4 files implemented (~225 lines), 20 files are empty scaffolds. No tests, CI, docs, or build system.

## Structure

```
plugin/ghostgit.vim          # defines :GStatus and :Git
autoload/ghostgit/           # functions: core.vim, git.vim, status.vim, util.vim
  job.vim state.vim blame.vim branch.vim commit.vim diff.vim log.vim remote.vim  (empty)
ftplugin/ghostgit/           # all empty
syntax/ghostgit/             # all empty
doc/                         # ghostgit.txt (empty), tags (empty)
test/                        # run_tests.vim, helpers/, specs/ — all empty
```

## Commands

- `:GStatus` — scratch buffer with `git status --short --branch`, keymaps: `r` refresh, `s` stage, `u` unstage
- `:Git <args>` — runs arbitrary git command

## Conventions

- VimL with `abort` on every function
- Namespace: `ghostgit#{module}#{function}`
- Buffer naming: `ghostgit://<name>`, filetype: `ghostgit_<name>`
- Messaging: `ghostgit#util#Error/Info/Warn` (not `echo`/`echom` directly)
- Scratch buffers: `bufhidden=wipe`, `nomodifiable`, `noswapfile`, `nofoldenable`
- Status buffer header: `['  GhostGit — ' . branch, repeat('─', 40), '']`
- git# wrappers pass `l:cwd` (RepoRoot) as optional second arg to core#Run

## Adding a new feature

1. Create `autoload/ghostgit/<feature>.vim` following the `ghostgit#{module}#{func}` pattern
2. Wire up commands in `plugin/ghostgit.vim`
3. Add filetype-specific settings in `ftplugin/ghostgit/<feature>.vim`
4. Add syntax in `syntax/ghostgit/<feature>.vim`
5. Add spec scaffold in `test/specs/`

## Skeleton code for a new module

```vim
" ============================================================================
" ghostgit.vim - <Feature>
" ============================================================================

function! ghostgit#<feature>#<Func>(...) abort
  let l:cwd = get(a:000, 0, '')
  let l:output = ghostgit#core#Run(['<git-command>'], l:cwd)
  " ... use ghostgit#util#OpenBuffer, ghostgit#util#Render, etc.
endfunction
```
