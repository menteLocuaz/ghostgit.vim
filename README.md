# ghostgit.vim

A minimalist Git UI plugin for Vim and Neovim. Provides scratch-buffer interfaces for common Git workflows.

## Commands

| Command | Description |
|---------|-------------|
| `:GStatus` | Open repository status (short + branch) |
| `:GLog` | Open commit log (oneline + graph) |
| `:Git <args>` | Run an arbitrary git command |

### Status buffer keymaps

| Key | Action |
|-----|--------|
| `s` | Stage file under cursor |
| `u` | Unstage file under cursor |
| `<cr>` | Open diff for file under cursor |
| `cc` | Open commit window |
| `ca` | Amend last commit |
| `r` | Refresh status |
| `q` / `<C-c>` | Close buffer |

### Log buffer keymaps

| Key | Action |
|-----|--------|
| `<cr>` | View commit details (placeholder) |
| `r` | Refresh log |
| `q` / `<C-c>` | Close buffer |

## Installation

With any plugin manager (vim-plug, packer, lazy.nvim, etc.):

```vim
" vim-plug
Plug 'arancamon/ghostgit.vim'
```

## Requirements

- Vim 8.0+ or Neovim 0.5+
- `git` in `$PATH`

## Architecture

```
plugin/ghostgit.vim          Entry point, command definitions
autoload/ghostgit/
  core.vim                   Core Git API (Run, RepoRoot, CurrentBranch, IsRepo)
  git.vim                    Git command wrappers (Status, Add, Reset, Diff, Log, etc.)
  job.vim                    Async job runner (Neovim/Vim8/sync fallback)
  util.vim                   Buffer/window management, rendering, messaging
  state.vim                  Global state manager
  parser.vim                 Parse git output lines
  render.vim                 Buffer renderers (status, log, diff, branches)
  status.vim                 Status buffer controller
  log.vim                    Log buffer controller
  diff.vim                   Diff preview buffer
  action.vim                 File-open actions from status lines
ftplugin/ghostgit/           Filetype-specific settings
syntax/ghostgit/             Syntax highlighting definitions
```

Uses `jobstart()` (Neovim) or `job_start()` (Vim8) with synchronous `systemlist()` fallback. Scratch buffers follow `bufhidden=wipe`, `nomodifiable`, `noswapfile`, `nofoldenable` conventions.

## License

Apache 2.0
