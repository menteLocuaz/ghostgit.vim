# ghostgit.vim — Infrastructure

## Overview

A minimalist Vim plugin for git operations. 11 modules implemented (~600 lines), 9 empty scaffolds. Designed for lazy-loading via Vim's autoload mechanism.

## Directory Structure

```text
ghostgit.vim/
├── AGENTS.md                   Agent development guide
├── LICENSE                     Apache 2.0
├── plugin/
│   └── ghostgit.vim            Entry point — defines :GStatus, :GLog, :Git
├── autoload/
│   └── ghostgit/
│       ├── core.vim            Core git execution engine
│       ├── git.vim             High-level git command wrappers
│       ├── status.vim          :GStatus buffer logic
│       ├── util.vim            UI utilities (buffer mgmt, messaging)
│       ├── state.vim           Global state manager (repos, buffers)
│       ├── job.vim             Async job runner (Neovim/Vim8/fallback)
│       ├── parser.vim          Git output parsers (status, log)
│       ├── render.vim          Output renderers (status, log)
│       ├── action.vim          Status buffer actions (OpenFile)
│       ├── log.vim             :GLog viewer
│       ├── diff.vim            Diff preview buffer
│       ├── test.vim            Test setup helpers (temp repos)
│       ├── blame.vim           (empty) — git blame
│       ├── branch.vim          (empty) — branch operations
│       ├── commit.vim          (empty) — committing
│       └── remote.vim          (empty) — remote management
├── ftplugin/ghostgit/
│   ├── status.vim              Status buffer settings
│   ├── diff.vim                Diff buffer settings
│   ├── log.vim                 Log buffer settings
│   ├── blame.vim               (empty)
│   └── commit.vim              (empty)
├── syntax/ghostgit/
│   ├── status.vim              Status buffer syntax highlighting
│   ├── log.vim                 Log buffer syntax highlighting
│   ├── commit.vim              (empty)
│   └── blame.vim               (empty)
├── doc/
│   ├── ghostgit.txt            (empty) — Vim help doc
│   └── tags                    (empty)
└── test/
    ├── run_tests.vim           Test runner instructions (vader.vim)
    ├── helpers/
    │   └── assert.vim          (empty)
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
        └── log.vader           Log viewer tests (12)
```

## Layered Architecture

```text
  User Commands (:GStatus, :GLog, :Git)
         │
         ▼
  plugin/ghostgit.vim        Thin command definitions only
         │
         ▼
  ┌──────────────────────────────────────────┐
  │  LAYER 4 — Feature Modules               │
  │  status.vim  diff.vim  log.vim  action   │
  │  Depends on: git.vim, util.vim, parser,  │
  │              render, state, job           │
  ├──────────────────────────────────────────┤
  │  LAYER 3 — State & Async                 │
  │  state.vim   job.vim   parser.vim        │
  │  Depends on: util.vim, core.vim          │
  ├──────────────────────────────────────────┤
  │  LAYER 2 — Semantic Wrappers             │
  │  git.vim: Status, Log, Diff, Add, Reset  │
  │  Depends on: core.vim                    │
  ├──────────────────────────────────────────┤
  │  LAYER 1 — Core Execution                │
  │  core.vim: Run, RepoRoot, IsRepo         │
  │  Depends on: util.vim (Error)            │
  ├──────────────────────────────────────────┤
  │  LAYER 0 — Presentation Primitives       │
  │  util.vim: OpenBuffer, Render, Messages  │
  │  render.vim: Status, Log formatting      │
  │  No internal dependencies                │
  └──────────────────────────────────────────┘
         │
         ▼
  Test Layer (vader.vim)
  11 spec files — 77 tests — 129 assertions
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
| `Status(items)` | Renders status buffer: header, staged/unstaged/untracked sections, help footer |
| `Log(items)` | Renders log buffer: header, commit entries (preserving graph prefix), help footer |

### Layer 1 — `autoload/ghostgit/core.vim`

Single point of git execution via `systemlist()`. All git commands flow through `Run()`.

| Function | Git Command |
|---|---|
| `Run(args, ...cwd)` | `git <args>` — polymorphic (list or string). Returns list of lines or `[]` on error. |
| `RepoRoot(...cwd)` | `git rev-parse --show-toplevel` |
| `CurrentBranch(...cwd)` | `git rev-parse --abbrev-ref HEAD` |
| `IsRepo(...cwd)` | `git rev-parse --git-dir` |

### Layer 1 — `autoload/ghostgit/parser.vim`

Parses git command output into structured dicts.

| Function | Input | Output |
|---|---|---|
| `ParseStatusLine(line)` | `M  foo.txt` | `{index, worktree, file}` |
| `Classify(item)` | status item | `'staged'\|'unstaged'\|'untracked'\|'unmodified'` |
| `ParseLogLine(line)` | `* 1a2b3c4 Fix` | `{graph, hash, subject}` or `{}` |

### Layer 2 — `autoload/ghostgit/git.vim`

Semantic wrappers. Feature modules call these, never raw `core#Run`.

| Function | Git Command |
|---|---|
| `Status(...cwd)` | `git status --short --branch` |
| `Log(...cwd)` | `git log --oneline --decorate --graph -100` |
| `Diff(file, ...cwd)` | `git diff [--cached] <file>` |
| `Add(file, ...cwd)` | `git add <file>` |
| `Reset(file, ...cwd)` | `git reset HEAD <file>` |

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
| `SaveView(name)` / `RestoreView(name)` | Saves/restores cursor position and scroll via `winsaveview()` |

### Layer 3 — `autoload/ghostgit/job.vim`

Abstracts async job execution across Vim/Neovim. Three backends: `jobstart()` (Neovim), `job_start()` (Vim8), `systemlist()` (fallback).

| Function | Purpose |
|---|---|
| `IsAvailable()` | Returns 1 if true async jobs available |
| `Run(cmd, opts)` | Runs command async. `opts`: `cwd`, `on_stdout(ch,lines)`, `on_stderr(ch,lines)`, `on_exit(job,code)`. Returns job ID or `-1` (sync). |
| `Wait(job_id)` | Blocks until job finishes (poll loop where `job_wait` unavailable) |
| `Stop(job_id)` | Kills a running job |

**Callback ordering note:** Vim8 delivers `exit_cb` before `out_cb`. Feature modules using async should account for this or use synchronous `core#Run` instead.

### Layer 4 — `autoload/ghostgit/status.vim`

End-to-end implementation of `:GStatus`.

| Function | Purpose |
|---|---|
| `Open()` | Entry point — checks repository, opens buffer, sets keymaps: `r` refresh, `s` stage, `u` unstage, `<cr>` diff, `cc` commit |
| `Refresh()` | Rebuilds buffer via `git#Status` → `parser#ParseStatusLine` → `render#Status` → `util#Render` |
| `Stage()` | Stages file under cursor via `git#Add` + refresh |
| `Unstage()` | Unstages file under cursor via `git#Reset` + refresh |
| `Diff()` | Opens diff buffer for item under cursor |
| `Commit()` | Opens commit buffer (placeholder) |

Uses `state#SetBuffer`, `state#CacheItems`, `state#SaveView`/`RestoreView`.

### Layer 4 — `autoload/ghostgit/log.vim`

End-to-end implementation of `:GLog`.

| Function | Purpose |
|---|---|
| `Open()` | Entry point — checks repository, opens buffer, sets keymaps: `<cr>` view commit, `r` refresh, `q` close |
| `Refresh()` | Rebuilds buffer via `git#Log` → `parser#ParseLogLine` → `render#Log` → `util#Render` |
| `HashAtCursor()` | Returns commit hash (7+ hex chars) at cursor, or empty string |
| `OpenCommit()` | Placeholder — echoes commit hash via `util#Info` |

### Layer 4 — `autoload/ghostgit/action.vim`

Actions triggered from status/log buffer keymaps.

| Function | Purpose |
|---|---|
| `OpenFile()` | `:edit!` the file under cursor (parsed from status buffer line) |
| `VSplitFile()` | `:vsplit!` the file under cursor |

### Layer 4 — `autoload/ghostgit/diff.vim`

| Function | Purpose |
|---|---|
| `Open(file, ...extra_args)` | Opens `ghostgit://diff/<file>` with `git diff` output |

## Dependency Graph

```text
util.vim ──── no deps
render.vim ── no deps

core.vim ──── util.vim (Error)

git.vim ───── core.vim (Run)

state.vim ─── core.vim (RepoRoot)
parser.vim ── no deps

status.vim ── core.vim (IsRepo, RepoRoot, CurrentBranch)
              git.vim  (Status, Add, Reset)
              util.vim (OpenBuffer, Render, Error, Info)
              state.vim (SetBuffer, CacheItems, SaveView, RestoreView)
              parser.vim (ParseStatusLine)
              render.vim (Status)

diff.vim ──── core.vim (Run)
              util.vim (OpenBuffer, Render)

log.vim ───── core.vim (IsRepo)
              git.vim  (Log)
              util.vim (OpenBuffer, Render, Error, Info)
              state.vim (SetBuffer, CacheItems, SaveView, RestoreView)
              parser.vim (ParseLogLine)
              render.vim (Log)

action.vim ── no deps (parses getline directly)

job.vim ───── no deps (uses has(), vim built-ins)

test.vim ──── no deps (uses systemlist directly)
```

## Key Design Patterns

1. **Autoload-on-Demand** — All logic in `autoload/ghostgit/*.vim`. Plugin file defines only commands. Zero startup cost for unused features.

2. **Thin Plugin / Fat Autoload** — `plugin/ghostgit.vim` is ~13 lines. Everything else is lazy-loaded.

3. **`cwd` Propagation** — Every git function accepts optional `cwd` arg, enabling operations on any repository without `cd`.

4. **Polymorphic `Run`** — Accepts list (programmatic) or string (`:Git` command), normalizes internally.

5. **Centralized Error Handling** — `core#Run` is single point of failure. Non-zero exit → error message + `[]`.

6. **Render-Only Buffer Pattern** — Full buffer rewrite on every `Refresh()`. Simple and correct for small git output.

7. **Scratch Buffer Reuse** — `bufwinnr()` check prevents duplicate buffers for the same feature.

8. **Namespaced Functions** — `ghostgit#{module}#{Function}` matches Vim's autoload convention.

9. **Parse → Render Pipeline** — Raw git output is parsed into structured items, cached in state, then rendered. Feature modules never format raw output.

10. **Test Isolation** — Every test creates a real temp git repository, runs operations, then cleans up (`ghostgit#test#Setup` / `Teardown`).

## Naming Conventions

| Aspect | Convention |
|---|---|
| Functions | `ghostgit#{module}#{function}` |
| Buffer names | `ghostgit://<name>` |
| File types | `ghostgit_<name>` |
| Messaging | `ghostgit#util#Error/Info/Warn` |
| All functions | `abort` modifier |
| Test files | `test/specs/<module>.vader` |
| Test framework | [vader.vim](https://github.com/junegunn/vader.vim) |

## Feature Expansion Pattern

Adding a new feature requires 5 locations (from `AGENTS.md`):

1. `autoload/ghostgit/<feature>.vim` — implementation
2. `plugin/ghostgit.vim` — Ex command
3. `ftplugin/ghostgit/<feature>.vim` — file type settings
4. `syntax/ghostgit/<feature>.vim` — syntax highlighting
5. `test/specs/<feature>.vader` — tests

## Testing

Framework: [vader.vim](https://github.com/junegunn/vader.vim) (not themis).

Run from project root:
```bash
PROJ=$(pwd)
vim -c "set rtp^=\$PROJ" -c 'Vader! test/specs/*.vader' -c 'q!'
```

11 spec files — 77 tests — 129 assertions. All green.

Tests create real temporary git repos via `ghostgit#test#Setup()` and clean up via `ghostgit#test#Teardown()`.

## Roadmap

| Module | Status | Description |
|---|---|---|
| `core.vim` | Done | Git execution engine |
| `util.vim` | Done | Buffer/message primitives |
| `state.vim` | Done | Global state manager |
| `parser.vim` | Done | Status + log line parsers |
| `render.vim` | Done | Status + log formatters |
| `job.vim` | Done | Async job abstraction |
| `git.vim` | Done | High-level git wrappers |
| `status.vim` | Done | `:GStatus` viewer |
| `diff.vim` | Done | Diff preview buffer |
| `action.vim` | Done | File open actions |
| `log.vim` | Done | `:GLog` viewer |
| `commit.vim` | Scaffold | Commit message composition |
| `blame.vim` | Scaffold | `:GBlame` scratch buffer |
| `branch.vim` | Scaffold | Branch browsing / checkout |
| `remote.vim` | Scaffold | Push / pull / fetch |
