# ghostgit.vim — Infrastructure

## Overview

A minimalist Vim plugin for git operations. Early-stage project with 4 implemented modules and 20 empty scaffolds. Designed for lazy-loading via Vim's autoload mechanism.

## Directory Structure

```
ghostgit.vim/
├── AGENTS.md                   Agent development guide
├── LICENSE                     Apache 2.0
├── plugin/
│   └── ghostgit.vim            Entry point — defines :GStatus and :Git
├── autoload/
│   └── ghostgit/
│       ├── core.vim            Core git execution engine
│       ├── git.vim             High-level git command wrappers
│       ├── status.vim          :GStatus buffer logic
│       ├── util.vim            UI utilities (buffer mgmt, messaging)
│       ├── state.vim           (empty) — state/persistence
│       ├── job.vim             (empty) — async job management
│       ├── blame.vim           (empty) — git blame
│       ├── branch.vim          (empty) — branch operations
│       ├── commit.vim          (empty) — committing
│       ├── diff.vim            (empty) — diff viewing
│       ├── log.vim             (empty) — git log
│       └── remote.vim          (empty) — remote management
├── ftplugin/ghostgit/          (empty) — filetype settings
├── syntax/ghostgit/            (empty) — syntax highlighting
├── doc/
│   ├── ghostgit.txt            (empty) — Vim help doc
│   └── tags                    (empty)
└── test/
    ├── run_tests.vim           (empty) — test runner
    ├── helpers/                (empty) — test helpers
    └── specs/
        ├── core_spec.vim       Tests for ghostgit#core#
        └── *spec.vim           (empty) — scaffold specs
```

## Layered Architecture

```
  User Commands (:GStatus, :Git)
         │
         ▼
  plugin/ghostgit.vim        Thin command definitions only
         │
         ▼
  ┌─────────────────────────────────────┐
  │  LAYER 3 — Feature Modules          │
  │  status.vim (blame, branch, ...)    │
  │  Depends on: core.vim, git.vim,     │
  │              util.vim               │
  ├─────────────────────────────────────┤
  │  LAYER 2 — Semantic Wrappers        │
  │  git.vim: Status, Log, Diff, Add... │
  │  Depends on: core.vim               │
  ├─────────────────────────────────────┤
  │  LAYER 1 — Core Execution           │
  │  core.vim: Run, RepoRoot, IsRepo    │
  │  Depends on: util.vim               │
  ├─────────────────────────────────────┤
  │  LAYER 0 — Presentation Primitives  │
  │  util.vim: OpenBuffer, Render, Msgs │
  │  No internal dependencies           │
  └─────────────────────────────────────┘
         │
         ▼
  Test Layer (themis framework)
  core_spec.vim (+ 7 scaffold specs)
```

## Module Reference

### Layer 0 — `autoload/ghostgit/util.vim`

Standalone UI primitives used by every other module.

| Function | Purpose |
|---|---|
| `OpenBuffer(name, ...mods)` | Opens/reuses scratch buffer `ghostgit://<name>`. Sets `bufhidden=wipe`, `noswapfile`, `nomodifiable`, `nofoldenable`, `nowrap`, `cursorline`. Filetype → `ghostgit_<name>`. Maps `q` to close. |
| `Render(lines)` | Destructive full-buffer content replacement. |
| `Error(msg)` / `Info(msg)` / `Warn(msg)` | User-facing messages with `[ghostgit]` prefix. |

### Layer 1 — `autoload/ghostgit/core.vim`

Single point of git execution via `systemlist()`. All git commands flow through `Run()`.

| Function | Git Command |
|---|---|
| `Run(args, ...cwd)` | `git <args>` — polymorphic (list or string). Returns list of lines or `[]` on error. |
| `RepoRoot(...cwd)` | `git rev-parse --show-toplevel` |
| `CurrentBranch(...cwd)` | `git rev-parse --abbrev-ref HEAD` |
| `IsRepo(...cwd)` | `git rev-parse --git-dir` |

### Layer 2 — `autoload/ghostgit/git.vim`

Semantic wrappers. Feature modules call these, never raw `core#Run`.

| Function | Git Command |
|---|---|
| `Status(...cwd)` | `git status --short --branch` |
| `Log(...cwd)` | `git log --oneline --decorate --graph -50` |
| `Diff(...cwd)` | `git diff` |
| `Blame(file, ...cwd)` | `git blame --porcelain <file>` |
| `Add(file, ...cwd)` | `git add <file>` |
| `Reset(file, ...cwd)` | `git reset HEAD <file>` |

### Layer 3 — `autoload/ghostgit/status.vim`

End-to-end implementation of `:GStatus`. Uses `core#IsRepo`, `util#OpenBuffer`, `git#Status`, `util#Render`.

| Function | Purpose |
|---|---|
| `Open()` | Entry point — checks repo, opens buffer, sets keymaps (`r` refresh, `s` stage, `u` unstage) |
| `Refresh()` | Rebuilds buffer with branch header + status output |
| `StageFile()` | Stages file under cursor via `git#Add` |
| `UnstageFile()` | Unstages file under cursor via `git#Reset` |

## Dependency Graph

```
util.vim ─── no deps
    ↑
core.vim ─── util.vim (Error)
    ↑
git.vim ──── core.vim (Run)
    ↑
status.vim ─ core.vim (IsRepo, RepoRoot, CurrentBranch)
              git.vim  (Status, Add, Reset)
              util.vim (OpenBuffer, Render, Error, Info)
```

## Key Design Patterns

1. **Autoload-on-Demand** — All logic in `autoload/ghostgit/*.vim`. Plugin file defines only commands. Zero startup cost for unused features.

2. **Thin Plugin / Fat Autoload** — `plugin/ghostgit.vim` is 10 lines. Everything else is lazy-loaded.

3. **`cwd` Propagation** — Every git function accepts optional `cwd` arg, enabling operations on any repo without `cd`.

4. **Polymorphic `Run`** — Accepts list (programmatic) or string (`:Git` command), normalizes internally.

5. **Centralized Error Handling** — `core#Run` is single point of failure. Non-zero exit → error message + `[]`.

6. **Render-Only Buffer Pattern** — Full buffer rewrite on every `Refresh()`. Simple and correct for small git output.

7. **Scratch Buffer Reuse** — `bufwinnr()` check prevents duplicate buffers for the same feature.

8. **Namespaced Functions** — `ghostgit#{module}#{Function}` matches Vim's autoload convention.

## Naming Conventions

| Aspect | Convention |
|---|---|
| Functions | `ghostgit#{module}#{function}` |
| Buffer names | `ghostgit://<name>` |
| Filetypes | `ghostgit_<name>` |
| Messaging | `ghostgit#util#Error/Info/Warn` |
| All functions | `abort` modifier |

## Feature Expansion Pattern

Adding a new feature requires 5 locations (from `AGENTS.md`):

1. `autoload/ghostgit/<feature>.vim` — implementation
2. `plugin/ghostgit.vim` — Ex command
3. `ftplugin/ghostgit/<feature>.vim` — filetype settings
4. `syntax/ghostgit/<feature>.vim` — syntax highlighting
5. `test/specs/<feature>_spec.vim` — tests

## Testing

Framework: [themis](https://github.com/thinca/vim-themis) (`describe`/`it`/`before`/`after`).

Implemented: `core_spec.vim` — 12 tests covering `Run`, `RepoRoot`, `CurrentBranch`, `IsRepo`. Tests create real temporary git repos and clean up after.

## Roadmap (Scaffold Modules)

| Module | Status | Description |
|---|---|---|
| `state.vim` | Scaffold | Plugin state / persistence |
| `job.vim` | Scaffold | Async job support (Vim 8 / Neovim) |
| `blame.vim` | Scaffold | `:GBlame` scratch buffer |
| `branch.vim` | Scaffold | Branch browsing / checkout |
| `commit.vim` | Scaffold | Commit message composition |
| `diff.vim` | Scaffold | Diff viewer |
| `log.vim` | Scaffold | `:GLog` browser |
| `remote.vim` | Scaffold | Push / pull / fetch |
