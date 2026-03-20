# VimSession_plug

Per-directory Vim session management built on top of `:mksession`.

This plugin stores one session file per working directory under `~/.vim_sessions/` by default, loads the session for the current directory on startup, and saves it again on exit.

## Behavior

- On `VimEnter`, load the session for the current working directory if it exists.
- If no session exists yet, create it immediately.
- On `VimLeavePre`, save the session automatically.
- If NERDTree is installed, session restore repairs placeholder tree buffers so reopening Vim does not leave an empty left pane behind.

## Installation

With `vim-plug`:

```vim
Plug 'kh-rawad/VimSession_plug'
```

For a local checkout:

```vim
Plug '~/VimSession_plug'
```

## Commands

- `:SessionLoad` loads the session for the current working directory.
- `:SessionSave` saves the session for the current working directory.
- `:SessionDelete` deletes the current session file and skips the next automatic save on exit.
- `:SessionPath` prints the full path to the current session file.

## Configuration

Default settings:

```vim
let g:vimsession_directory = '~/.vim_sessions'
let g:vimsession_auto_load = 1
let g:vimsession_auto_save = 1
let g:vimsession_create_on_start = 1
```

Example:

```vim
let g:vimsession_directory = '~/.vim_sessions'
let g:vimsession_auto_load = 1
let g:vimsession_auto_save = 1
let g:vimsession_create_on_start = 1
```

## Notes

- Session filenames are derived from the normalized working directory path, so different directories get different session files automatically.
- The help file lives at `doc/vimsession.txt`. If you update it, regenerate tags with `:helptags doc`.
