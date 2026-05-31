# ghostgit.vim — Infrastructure

## Overview

A minimalist Vim plugin for git operations. 18 modules implemented (~2600 lines). Designed for lazy-loading via Vim's autoload mechanism.

## Directory Structure

```text
ghostgit.vim/
├── AGENTS.md                   Agent development guide
├── LICENSE                     Apache 2.0
├── skills-lock.json            Agent skills lock file
├── .github/                    GitHub workflows
├── docs/
│   └── infrastructure.md       This document
├── plugin/
│   └── ghostgit.vim            Entry point — defines :GStatus, :GLog, :GBlame, :GCommit,
│                                            :GDiff, :GBrowse, :Git, :G
├── autoload/
│   └── ghostgit/
│       ├── core.vim            Core git execution engine + Execute() for smart output
│       ├── git.vim             High-level git command wrappers (Status, Log, Add,
│       │                       Reset, Diff, Checkout, Push, Pull, Branch, Commit)
│       ├── status.vim          :GStatus buffer logic
│       ├── util.vim            UI utilities (buffer mgmt, messaging)
│       ├── state.vim           Global state manager (repos, buffers)
│       ├── job.vim             Async job runner (Neovim/Vim8/fallback)
│       ├── parser.vim          Git output parsers (status, log)
│       ├── render.vim          Output renderers (status, log, diff, branches, generic)
│       ├── action.vim          Action dispatcher (dispatch, open, vsplit, diff, stage, unstage)
│       ├── log.vim             :GLog viewer
│       ├── diff.vim            Diff preview buffer (file, staged, commit comparison)
│       ├── commit.vim          Commit message composition editor
│       ├── blame.vim           :GBlame scratch buffer
│       ├── branch.vim          Branch listing and checkout
│       ├── remote.vim          Remote operations (:GBrowse)
│       ├── complete.vim        Tab-completion for :Git/:G commands
│       ├── highlights.vim      Syntax highlight group definitions
│       └── test.vim            Test setup helpers (temp repos)
├── ftplugin/
│   ├── ghostgit_status.vim     Status buffer settings and keymaps
│   ├── ghostgit_log.vim        Log buffer settings and keymaps
│   ├── ghostgit_diff.vim       Diff buffer settings
│   ├── ghostgit_blame.vim      (empty) — blame buffer settings
│   └── ghostgit_commit.vim     (empty) — commit buffer settings
├── syntax/
│   ├── ghostgit_status.vim     Status buffer syntax highlighting (64 lines)
│   ├── ghostgit_log.vim        Log buffer syntax highlighting (18 lines)
│   └── ghostgit_commit.vim     (empty) — commit buffer syntax
├── doc/
│   ├── ghostgit.txt            (empty) — Vim help doc
│   └── tags                    (empty)
└── test/
    ├── run_tests.vim           Test runner instructions (vader.vim)
    ├── helpers/
    │   └── assert.vim          AssertEquals, AssertTrue, AssertNotEmpty
    └── specs/
        ├── core.vader          Core execution tests (10)
        ├── state.vader         State manager tests (13)
        ├── util.vader          UI util tests (6)
        ├── parser.vader        Parser tests (8)
        ├── render.vader        Render tests (5)
        ├── git.vader           Git wrapper tests (4)
        ├── diff.vader          Diff buffer tests (2)
        ├── status.vader        Status buffer tests (3)
        ├── job.vader           Async job tests (8)
        ├── action.vader        Action tests (6)
        ├── log.vader           Log viewer tests (12)
        ├── remote_spec.vim     (empty) — remote tests
        ├── branch_spec.vim     (empty) — branch tests
        ├── log_spec.vim        (empty) — log tests
        ├── commit_spec.vim     (empty) — commit tests
        ├── blame_spec.vim      (empty) — blame tests
        ├── diff_spec.vim       (empty) — diff tests
        └── status_spec.vim     (empty) — status tests
```

## Layered Architecture

```text
  User Commands (:GStatus, :GLog, :GBlame, :GCommit, :GDiff, :GBrowse, :Git, :G)
         │
         ▼
  plugin/ghostgit.vim        Thin command definitions only
         │
         ▼
  ┌──────────────────────────────────────────────┐
  │  LAYER 4 — Feature Modules                   │
  │  status.vim  log.vim  diff.vim  commit.vim   │
  │  blame.vim  branch.vim  remote.vim           │
  │  action.vim                                  │
  │  Depends on: git.vim, util.vim, parser,      │
  │              render, state, job               │
  ├──────────────────────────────────────────────┤
  │  LAYER 3 — State & Async                     │
  │  state.vim   job.vim   parser.vim            │
  │  Depends on: util.vim, core.vim              │
  ├──────────────────────────────────────────────┤
  │  LAYER 2 — Semantic Wrappers                 │
  │  git.vim: Status, Log, Diff, Add, Reset,     │
  │          Checkout, Push, Pull, etc.          │
  │  Depends on: core.vim                        │
  ├──────────────────────────────────────────────┤
  │  LAYER 1 — Core Execution                    │
  │  core.vim: Run, Execute, RepoRoot,           │
  │           CurrentBranch, IsRepo, ListBranches │
  │  Depends on: util.vim (Error)                │
  ├──────────────────────────────────────────────┤
  │  LAYER 0 — Presentation Primitives           │
  │  util.vim: OpenBuffer, Render, Messages      │
  │  render.vim: Status, Log, Diff, Branches     │
  │  highlights.vim: highlight group definitions │
  │  No internal dependencies                    │
  └──────────────────────────────────────────────┘
         │
         ▼
  Service Modules (cross-cutting)
  complete.vim — tab-completion for :Git/:G
  test.vim     — temp repo setup/teardown for specs

  Test Layer (vader.vim)
  11 .vader spec files — 77 tests — 129 assertions
  7 _spec.vim scaffold files (empty)
```

## Module Reference

### Layer 0 — `autoload/ghostgit/util.vim`

Standalone UI primitives used by every other module.

| Function | Purpose |
|---|---|
| `OpenBuffer(name, ...mods)` | Opens/reuses scratch buffer `ghostgit://<name>`. Sets `bufhidden=wipe`, `noswapfile`, `nomodifiable`, `nofoldenable`, `nowrap`, `cursorline`. File type → `ghostgit_<name>`. Maps `q` to close. |
| `Render(lines)` | Destructive full-buffer content replacement. |
| `Error(msg)` / `Info(msg)` / `Warn(msg)` | User-facing messages with `[ghostgit]` prefix. |

### Layer 0 — `autoload/ghostgit/render.vim`

Formats structured data into display lines.

| Function | Purpose |
|---|---|
| `Status(items)` | Renders status buffer: header with branch name, staged/unstaged/untracked/conflicted sections, summary stats, legend, help footer |
| `Log(items)` | Renders log buffer: header, commit entries (preserving graph prefix), help footer |
| `Diff(diff_lines)` | Passes through diff output unchanged |
| `Branches(branches)` | Renders branch list: header, local branches (current marked with `*`), remote branches |
| `Generic(title, content_lines)` | Wraps content with a title header and `=` underline |

### Layer 0 — `autoload/ghostgit/highlights.vim`

| Function | Purpose |
|---|---|
| `Init()` | Defines highlight groups for GhostGit buffers. Links to standard groups (Title, DiffAdd, DiffChange, Error, etc.) with explicit GUI/cterm color overrides for dark/light backgrounds. |

### Layer 1 — `autoload/ghostgit/core.vim`

Single point of git execution via `systemlist()`. All git commands flow through `Run()`.

| Function | Git Command / Purpose |
|---|---|
| `Run(args, ...cwd)` | `git <args>` — polymorphic (list or string). Returns list of lines or `[]` on error. Uses `git -C <cwd>` to avoid global `cd`. |
| `Execute(args)` | Smart output for `:Git` — if empty opens `:GStatus`; if output >10 lines opens scratch buffer with syntax; otherwise echoes lines. |
| `RepoRoot(...cwd)` | `git rev-parse --show-toplevel`. Caches result in state. |
| `CurrentBranch(...cwd)` | `git rev-parse --abbrev-ref HEAD`. Returns `'HEAD detached at <hash>'` when applicable. |
| `IsRepo(...cwd)` | `git rev-parse --git-dir` (silent). Returns 1 if in a repo. |
| `ListBranches(...cwd)` | `git branch --format ...` + `git branch -r --format ...`. Returns combined local + remote branch list. |
| `LastCommit(...cwd)` | Returns dict `{hash, subject, author, date}` for HEAD. |

### Layer 1 — `autoload/ghostgit/parser.vim`

Parses git command output into structured dicts.

| Function | Input | Output |
|---|---|---|
| `ParseStatusOutput(lines)` | `['## main...origin/main', ' M foo.txt']` | `{branch, upstream, ahead, behind, items: [{index, worktree, file}]}` |
| `ParseStatusLine(line)` | `'M  foo.txt'` | `{index, worktree, file}` |
| `Classify(item)` | status item | `'staged' \| 'unstaged' \| 'untracked' \| 'conflicted' \| 'unmodified'` |
| `ParseLogLine(line)` | `'* 1a2b3c4 Fix'` | `{graph, hash, subject}` or `{}` for non-commit lines |

### Layer 2 — `autoload/ghostgit/git.vim`

Semantic wrappers over `core#Run`. Feature modules call these, never raw `core#Run`.

| Function | Git Command |
|---|---|
| `Status(...cwd)` | `git status --short --branch`. Supports async callback. |
| `Log(...cwd)` | `git log --oneline --decorate --graph -100`. Supports async callback. |
| `Diff(file, ...cwd)` | `git diff [--cached] -- <file>` |
| `Add(file, ...cwd)` | `git add -- <file>` (supports list of files) |
| `Reset(file, ...cwd)` | `git reset HEAD -- <file>` (supports list, empty list = all, and flag-based resets) |
| `Checkout(branch, ...)` | `git checkout <branch>` |
| `Push(...)` | `git push [--set-upstream origin <branch>]` |
| `Pull(...)` | `git pull` |
| `Branch(...cwd)` | `git branch` (raw output) |
| `Commit(message, ...)` | `git commit -m <message>` |
| `GetStagedFiles(...cwd)` | `git diff --cached --name-only` |
| `GetModifiedFiles(...cwd)` | `git diff --name-only` |
| `GetUntrackedFiles(...cwd)` | `git ls-files --others --exclude-standard` |

### Layer 3 — `autoload/ghostgit/state.vim`

Global state manager. Stores repository metadata and buffer state across the session.

| Function | Purpose |
|---|---|
| `Init()` | Creates `g:ghostgit_state` dict with `repos` and `buffers` sub-dicts. Idempotent. |
| `SetRepo(root)` | Registers a repository root in state |
| `GetRepo(...root)` | Returns repository dict (branch, git_dir, last_refresh) or `{}` |
| `SetBuffer(name, type)` | Stores current buffer metadata (bufnr, type, repository_root) |
| `GetBuffer(name)` | Returns buffer dict or `{}` |
| `RemoveBuffer(bufnr)` | Removes buffer entry by buffer number |
| `CacheItems(name, items)` | Caches structured data for a buffer (e.g. status items, log items) |
| `GetCachedItems(name)` | Retrieves cached items |
| `SetBufferData(name, data)` / `GetBufferData(name)` | Stores/retrieves arbitrary data keyed by buffer name |
| `SaveView(name)` / `RestoreView(name)` | Saves/restores cursor position and scroll via `winsaveview()` |

### Layer 3 — `autoload/ghostgit/job.vim`

Abstracts async job execution across Vim/Neovim. Three backends: `jobstart()` (Neovim), `job_start()` (Vim8), `systemlist()` (fallback). Supports a debounced job queue with priorities, cancellation, and channel-based stdout collection.

| Function | Purpose |
|---|---|
| `IsAvailable()` | Returns 1 if true async jobs available |
| `Run(cmd, opts)` | Runs command async. `opts`: `cwd`, `on_stdout(lines)`, `on_stderr(lines)`, `on_exit(code)`, `priority`, `bufnr`, `on_success(lines)`, `on_failure(err)`. Returns job ID or `-1` (sync). |
| `Debounce(key, ms, cmd, opts)` | Debounces jobs by key — cancels pending job for same key before scheduling new one |
| `Wait(job_id)` | Blocks until job finishes (poll loop where `job_wait` unavailable) |
| `Stop(job_id)` | Kills a running job |
| `CancelBuffer(bufnr)` | Cancels all pending jobs associated with a buffer |

### Layer 4 — `autoload/ghostgit/status.vim`

End-to-end implementation of `:GStatus`.

| Function | Purpose |
|---|---|
| `Open()` | Entry point — checks repository, opens buffer, registers `BufWipeout` cleanup autocmd |
| `Refresh()` | Rebuilds buffer via debounced `git#Status` → `parser#ParseStatusOutput` → `render#Status` → buffer write |
| `Stage()` | Stages file under cursor via `git#Add` + refresh |
| `Unstage()` | Unstages file under cursor via `git#Reset` + refresh |
| `Diff()` | Opens diff buffer for item under cursor (cached vs uncached depending on classification) |
| `Commit()` | Opens commit message editor via `commit#Open()` |
| `Amend()` | Opens commit message editor with `--amend` |

Uses `state#SetBuffer`, `state#CacheItems`, `state#SaveView`/`RestoreView`. Keymaps defined in `ftplugin/ghostgit_status.vim`: `s` stage, `u` unstage, `<cr>` diff, `o` open file, `v` vsplit file, `cc` commit, `r` refresh, `q` close.

### Layer 4 — `autoload/ghostgit/log.vim`

End-to-end implementation of `:GLog`.

| Function | Purpose |
|---|---|
| `Open()` | Entry point — checks repository, opens buffer, sets cleanup autocmd |
| `Refresh()` | Rebuilds buffer via debounced `git#Log` → `parser#ParseLogLine` → `render#Log` → buffer write |
| `HashAtCursor()` | Returns commit hash (7+ hex chars) at cursor, or empty string |
| `OpenCommit()` | Runs `git show <hash>` via `core#Execute` (opens scratch buffer with syntax) |

### Layer 4 — `autoload/ghostgit/diff.vim`

| Function | Purpose |
|---|---|
| `Open(file, ...extra_args)` | Opens `ghostgit://diff/<file>` with `git diff` output. Supports `--cached` via extra args. Includes `r` refresh, `q`/`<C-c>` close keymaps. |
| `Refresh()` | Rebuilds the current diff buffer using saved file + args state |
| `OpenStaged()` | Opens `ghostgit://diff/staged` with combined diffs of all staged files |
| `CompareCommits(commit1, commit2, ...path)` | Opens `ghostgit://diff/<c1>..<c2>` with commit comparison diff |

### Layer 4 — `autoload/ghostgit/commit.vim`

| Function | Purpose |
|---|---|
| `Open(...opts)` | Opens `.git/COMMIT_EDITMSG` in a split. Sets `<C-c><C-c>` to finish, `q` to close. Shows info message. |
| `Finish()` | Writes buffer, closes it, runs `git commit -F <file> [opts]`, refreshes status buffer if open. |

### Layer 4 — `autoload/ghostgit/blame.vim`

| Function | Purpose |
|---|---|
| `Open()` | Runs `git blame -- <current-file>`, opens scratch buffer `ghostgit://blame/<file>`, sets filetype `ghostgit_blame`, maps `q` to close. |

### Layer 4 — `autoload/ghostgit/branch.vim`

| Function | Purpose |
|---|---|
| `Open()` | Lists branches via `core#ListBranches`, renders via `render#Branches`, opens scratch buffer. Maps `<cr>` to checkout, `q` to close. |
| `Checkout()` | Checks out branch under cursor via `git#Checkout`, closes buffer. |

### Layer 4 — `autoload/ghostgit/remote.vim`

| Function | Purpose |
|---|---|
| `Browse()` | Gets remote origin URL via `git remote get-url origin`, converts SSH → HTTPS, opens in system browser (`xdg-open`/`open`/`start`). |

### Layer 4 — `autoload/ghostgit/action.vim`

| Function | Purpose |
|---|---|
| `Dispatch(action_name, ...target)` | Routes action to status or log handler based on filetype |
| `OpenFile()` | `:edit` the file under cursor (parsed from status buffer line) |
| `VSplitFile()` | `:vsplit` the file under cursor |

### Service — `autoload/ghostgit/complete.vim`

Context-aware tab-completion for `:Git` and `:G` commands. Provides completion candidates based on subcommand:

| Function | Returns |
|---|---|
| `Complete(A, L, P)` | Entry point — delegates to `Subcommands()` or `Context(subcmd)` |
| `Subcommands()` | All git subcommands (add, bisect, branch, checkout, ...) |
| `Branches()` | Local + remote branch names |
| `ModifiedFiles()` | Modified file paths from `git status --porcelain` |
| `StagedFiles()` | Staged file paths from `git diff --cached --name-only` |
| `Remotes()` | Remote names from `git remote` |
| `Tags()` | Tag names from `git tag` |
| `TrackedFiles()` | Tracked files from `git ls-files` |
| `Stashes()` | Stash entries from `git stash list` |

### Service — `autoload/ghostgit/test.vim`

Test helpers for creating isolated temporary git repositories.

| Function | Purpose |
|---|---|
| `Setup()` | Creates temp dir, runs `git init -b main`, sets user config, creates initial commit. Returns temp dir path. |
| `SetupEmptyRepo()` | Same as Setup but without the initial commit. |
| `CreateFile(dir, path, content)` | Writes a file at `dir/path` with given content, creating parent dirs as needed. |
| `StageFile(dir, path)` | Runs `git add -- <path>` in the temp repo. |
| `Teardown(dir)` | Recursively deletes temp directory. |

## Dependency Graph

```text
util.vim ──── no deps
render.vim ── no deps
highlights.vim ── no deps

core.vim ──── util.vim (Error, Warn)
              state.vim (GetRepo, SetRepo)

git.vim ───── core.vim (Run)
              job.vim (Run, optional async)
              util.vim (Error)

state.vim ─── core.vim (RepoRoot)
parser.vim ── no deps
job.vim ───── no deps (uses has(), vim built-ins)

status.vim ── core.vim (IsRepo, RepoRoot, CurrentBranch)
              git.vim  (Status, Add, Reset)
              util.vim (OpenBuffer, Render, Error, Info)
              state.vim (SetBuffer, CacheItems, SaveView, RestoreView)
              parser.vim (ParseStatusOutput)
              render.vim (Status)
              job.vim (Debounce)

log.vim ───── core.vim (IsRepo)
              git.vim  (Log)
              util.vim (OpenBuffer, Render, Error, Info)
              state.vim (SetBuffer, CacheItems, SaveView, RestoreView)
              parser.vim (ParseLogLine)
              render.vim (Log)
              job.vim (Debounce)

diff.vim ──── core.vim (Run, IsRepo, RepoRoot)
              git.vim  (GetStagedFiles)
              util.vim (OpenBuffer, Render, Error, Info)
              state.vim (SetBufferData, GetBufferData)

commit.vim ── core.vim (Run, RepoRoot)
              util.vim (Info)
              status.vim (Refresh)

blame.vim ─── core.vim (Run, IsRepo)
              util.vim (OpenBuffer, Render, Error)

branch.vim ── core.vim (IsRepo, ListBranches)
              git.vim  (Checkout)
              render.vim (Branches)
              util.vim (OpenBuffer, Render, Info)

remote.vim ── core.vim (Run, IsRepo)
              util.vim (Error, Info)

action.vim ── util.vim (Error, Info, Warn)
              status.vim (Stage, Unstage, Diff)

complete.vim ── core.vim (Run, RepoRoot)

test.vim ──── no deps (uses systemlist directly)
```

## Key Design Patterns

1. **Autoload-on-Demand** — All logic in `autoload/ghostgit/*.vim`. Plugin file defines only commands. Zero startup cost for unused features.

2. **Thin Plugin / Fat Autoload** — `plugin/ghostgit.vim` is ~19 lines. Everything else is lazy-loaded.

3. **`cwd` Propagation** — Every git function accepts optional `cwd` arg, enabling operations on any repository without `cd`.

4. **Polymorphic `Run`** — Accepts list (programmatic) or string (`:Git` command), normalizes internally.

5. **Centralized Error Handling** — `core#Run` is single point of failure. Non-zero exit → error message + `[]`.

6. **Render-Only Buffer Pattern** — Full buffer rewrite on every `Refresh()`. Simple and correct for small git output.

7. **Scratch Buffer Reuse** — `bufwinnr()` check prevents duplicate buffers for the same feature.

8. **Namespaced Functions** — `ghostgit#{module}#{Function}` matches Vim's autoload convention.

9. **Parse → Render Pipeline** — Raw git output is parsed into structured items, cached in state, then rendered. Feature modules never format raw output.

10. **Test Isolation** — Every test creates a real temp git repository, runs operations, then cleans up (`ghostgit#test#Setup` / `Teardown`).

11. **Debounced Async Jobs** — Status and log buffers use debounced async jobs to prevent rapid successive refreshes from queuing redundant work.

12. **Smart Output Dispatch** — `core#Execute` routes short output to `echomsg` and long output to a syntax-highlighted scratch buffer.

## Naming Conventions

| Aspect | Convention |
|---|---|
| Functions | `ghostgit#{module}#{function}` |
| Buffer names | `ghostgit://<name>` |
| File types | `ghostgit_<name>` |
| Messaging | `ghostgit#util#Error/Info/Warn` |
| All functions | `abort` modifier |
| Test files (vader) | `test/specs/<module>.vader` |
| Test files (spec) | `test/specs/<module>_spec.vim` |
| Test framework | [vader.vim](https://github.com/junegunn/vader.vim) |
| ftplugin files | `ftplugin/ghostgit_<name>.vim` |
| syntax files | `syntax/ghostgit_<name>.vim` |

## Feature Expansion Pattern

Adding a new feature requires 5 locations (from `AGENTS.md`):

1. `autoload/ghostgit/<feature>.vim` — implementation
2. `plugin/ghostgit.vim` — Ex command
3. `ftplugin/ghostgit_<feature>.vim` — file type settings
4. `syntax/ghostgit_<feature>.vim` — syntax highlighting
5. `test/specs/<feature>.vader` or `test/specs/<feature>_spec.vim` — tests

## Testing

Framework: [vader.vim](https://github.com/junegunn/vader.vim).

Run from project root:
```bash
PROJ=$(pwd)
vim -c "set rtp^=\$PROJ" -c 'Vader! test/specs/*.vader' -c 'q!'
```

11 `.vader` spec files — 77 tests — 129 assertions. All green.
7 `_spec.vim` scaffold files for future tests (currently empty).

Tests create real temporary git repos via `ghostgit#test#Setup()` and clean up via `ghostgit#test#Teardown()`. The `test/helpers/assert.vim` module provides `Equals`, `True`, and `NotEmpty` assertion functions.

## Module Status

All 18 modules are implemented:

| Module | Status | Lines | Description |
|---|---|---|---|
| `core.vim` | Done | 197 | Git execution engine, smart output dispatch |
| `git.vim` | Done | 281 | High-level git wrappers (Status, Log, Add, Reset, Diff, Checkout, Push, Pull, Commit, Branch) |
| `job.vim` | Done | 472 | Debounced async job queue (Neovim/Vim8/fallback) |
| `parser.vim` | Done | 215 | Status + log output parsers |
| `render.vim` | Done | 238 | Status, log, diff, branches, generic renderers |
| `state.vim` | Done | 131 | Global repository + buffer state manager |
| `util.vim` | Done | 117 | Buffer management, rendering, messaging |
| `status.vim` | Done | 145 | `:GStatus` viewer |
| `log.vim` | Done | 89 | `:GLog` viewer |
| `diff.vim` | Done | 224 | Diff preview buffer (file, staged, commit comparison) |
| `commit.vim` | Done | 57 | Commit message composition editor |
| `action.vim` | Done | 88 | Action dispatcher (open, vsplit, stage, unstage, diff) |
| `blame.vim` | Done | 35 | `:GBlame` scratch buffer |
| `branch.vim` | Done | 31 | Branch listing and checkout |
| `remote.vim` | Done | 44 | `:GBrowse` (open remote in browser) |
| `complete.vim` | Done | 102 | Tab-completion for `:Git`/`:G` |
| `highlights.vim` | Done | 59 | Syntax highlight group definitions |
| `test.vim` | Done | 47 | Test helpers (temp repo setup/teardown) |
