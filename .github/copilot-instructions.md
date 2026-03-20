# Copilot instructions for this repository

## Commands

This repository does not define project-local build, lint, or automated test commands.

Manual verification is done from the repository root by loading the plugin from the local runtimepath and exercising the commands:

```sh
vim -Nu NONE -n \
  -c "set rtp+=." \
  -c "runtime plugin/vimsession.vim" \
  -c "SessionPath" \
  -c "SessionSave" \
  -c "SessionLoad" \
  -c "qall!"
```

If you change the help file, regenerate help tags:

```sh
vim -Nu NONE -n -c "helptags doc" -c "qall!"
```

## High-level architecture

- `plugin/vimsession.vim` is the thin entrypoint. It guards against double-loading, sets default `g:` options, defines the user commands, and wires the lifecycle through `VimEnter`/`VimLeavePre` autocmds.
- `autoload/vimsession.vim` contains all behavior. `vimsession#session_root()` resolves the session directory, `vimsession#session_file()` maps the current working directory to a stable session filename, and the remaining `vimsession#*` functions implement load/save/delete and auto-start/auto-save flows.
- `autoload/vimsession.vim` also owns session-repair helpers for plugin interoperability. Today that includes fixing placeholder `NERD_tree_tab_*` buffers after session restore when NERDTree is installed.
- `doc/vimsession.txt` is the canonical user-facing contract. When commands, defaults, or behavior change, keep this help file in sync and refresh `doc/tags`.

## Key conventions

- Keep `plugin/vimsession.vim` declarative. Put non-trivial logic in `autoload/vimsession.vim` and expose it through `vimsession#...` functions.
- User configuration is always read from globals with `get(g:, ..., default)`. Current defaults are:
  - `g:vimsession_directory`
  - `g:vimsession_auto_load`
  - `g:vimsession_auto_save`
  - `g:vimsession_create_on_start`
- Session files are keyed by normalized working directory path, not project name. The path is sanitized by replacing `/`, `\`, and `:` with `%`, collapsing whitespace and unsupported characters to `_`, trimming edge `%`, and appending an 8-character `sha256()` suffix when available. Preserve this mapping logic unless you intentionally migrate existing session filenames.
- Autocmd paths should stay quiet. `maybe_auto_start()` and `maybe_auto_save()` call the load/save functions with the silent flag so startup/exit remains non-noisy.
- The plugin uses global guard flags for control flow:
  - `g:vimsession_did_auto_start` prevents repeated startup work.
  - `g:vimsession_is_loading` suppresses save-on-exit while sourcing a session.
  - `g:vimsession_skip_auto_save_once` prevents immediately recreating a session after `:SessionDelete`.
  - `g:vimsession_active_file` tracks the current resolved session path.
- Interoperability fixes belong in the plugin, not in user config, when they are a direct consequence of `vimsession` loading/saving sessions.
- Existing user-visible messages use `echomsg`, with missing-session cases highlighted via `WarningMsg`. Match that style when adding new feedback.
