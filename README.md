# ghostgit.vim

A minimalist Git UI plugin for Vim and Neovim. Provides scratch-buffer interfaces for common Git workflows.

## Commands

| Command            | Description                                    |
| ------------------ | ---------------------------------------------- |
| `:GStatus`         | Open repository status (short + branch)        |
| `:GLog`            | Open commit log (oneline + graph)              |
| `:GBlame`          | Open git blame for the current file            |
| `:GCommit`         | Open commit message editor                     |
| `:GCommit --amend` | Amend the last commit                          |
| `:GDiff <file>`    | Open diff for a file                           |
| `:GBrowse`         | Open remote URL in browser                     |
| `:Git <args>`      | Run an arbitrary git command (with completion) |
| `:G <args>`        | Alias for `:Git`                               |

### Status buffer keymaps sxd

| Key    | Action                          |
| ------ | ------------------------------- |
| `s`    | Stage file under cursor         |
| `u`    | Unstage file under cursor       |
| `<cr>` | Open diff for file under cursor |
| `o`    | Open file under cursor          |
| `v`    | Open file in vertical split     |
| `cc`   | Open commit window              |
| `r`    | Refresh status                  |
| `q`    | Close buffer                    |

### Log buffer keymaps

| Key    | Action                   |
| ------ | ------------------------ |
| `<cr>` | View full commit details |
| `r`    | Refresh log              |
| `q`    | Close buffer             |

### Commit buffer keymaps

| Key          | Action            |
| ------------ | ----------------- |
| `<C-c><C-c>` | Finish and commit |
| `q`          | Close buffer      |

## Tab-completion

`:Git` and `:G` provide context-aware tab-completion for git subcommands, branch names, file paths, remotes, tags, and stashes.

## Installation

With any plugin manager (vim-plug, packer, lazy.nvim, etc.):

```vim
" vim-plug
Plug 'menteLocuaz/ghostgit.vim'
```

## Requirements

- Vim 8.0+ or Neovim 0.5+
- `git` in `$PATH`
- `xdg-open` (Linux), `open` (macOS), or `start` (Windows) for `:GBrowse`

## Architecture

```text
plugin/ghostgit.vim            Entry point, command definitions
autoload/ghostgit/
  core.vim                     Core Git API (Run, RepoRoot, CurrentBranch, IsRepo, Execute)
  git.vim                      Git command wrappers (Status, Add, Reset, Diff, Log, etc.)
  job.vim                      Async job runner (Neovim/Vim8/sync fallback)
  util.vim                     Buffer/window management, rendering, messaging
  state.vim                    Global state manager
  parser.vim                   Parse git output lines
  render.vim                   Buffer renderers (status, log, diff, branches)
  status.vim                   Status buffer controller
  log.vim                      Log buffer controller
  diff.vim                     Diff preview buffer
  commit.vim                   Commit message editor
  blame.vim                    Git blame viewer
  branch.vim                   Branch listing and checkout
  remote.vim                   Remote operations (browse)
  action.vim                   Action dispatcher for buffer keymaps
  complete.vim                 Tab-completion for :Git/:G commands
  highlights.vim               Syntax highlight group definitions
  test.vim                     Test helpers (temp repo setup/teardown)
ftplugin/ghostgit_status.vim   Status buffer settings and keymaps
ftplugin/ghostgit_log.vim      Log buffer settings and keymaps
ftplugin/ghostgit_diff.vim     Diff buffer settings and keymaps
ftplugin/ghostgit_blame.vim    Blame buffer settings
ftplugin/ghostgit_commit.vim   Commit buffer settings
syntax/ghostgit_status.vim     Status buffer syntax highlighting
syntax/ghostgit_log.vim        Log buffer syntax highlighting
syntax/ghostgit_commit.vim     Commit buffer syntax highlighting
test/                          Test runner and specs
```

Uses `jobstart()` (Neovim) or `job_start()` (Vim8) with synchronous `systemlist()` fallback. Async jobs are debounced and prioritized via a queue. Scratch buffers follow `bufhidden=wipe`, `nomodifiable`, `noswapfile`, `nofoldenable` conventions.

## License

- **[Apache 2.0] (./LICENSE)**

- **[Architecture](docs/infrastructure.md).**

