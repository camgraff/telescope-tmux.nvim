# Telescope-tmux.nvim

A Telescope.nvim extension for fuzzy-finding over tmux targets.

![demo](https://i.imgur.com/WvSXmaI.gif)

## Prerequisites

- [tmux](https://github.com/tmux/tmux)
- [Neovim nightly](https://github.com/neovim/neovim/releases/tag/nightly)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [nvim-terminal.lua](https://github.com/norcalli/nvim-terminal.lua) (for displaying terminal colors in the `pane_contents` previewer)


## Commands

### Sessions
Switch to another tmux session
```
:Telescope tmux sessions
```

|Mapping|Description|Modes|
|---|---|---|
|`<C-a>`|Create new session|n,i|
|`<C-d>`|Delete a session|n,i|
|`<C-r>`|Rename a session|n,i|

|Option|Description|Default value|
|---|---|---|
|`entry_format`|A [tmux format string](https://man7.org/linux/man-pages/man1/tmux.1.html#FORMATS) used to determine how to display the session entry|`#S`|

### Windows
Switch to another window
```
:Telescope tmux windows
```

|Mapping|Description|Modes|
|---|---|---|
|`<C-d>`|Delete a window|n,i|

|Option|Description|Default value|
|---|---|---|
|`entry_format`|A [tmux format string](https://man7.org/linux/man-pages/man1/tmux.1.html#FORMATS) used to determine how to display the window entry|`#S: #W`|

### Pane Contents
Find something in a pane's history scrollback
```
:Telescope tmux pane_contents
```

### Pane File Paths
Find file paths in pane's history scrollback and open them for editing
```
:Telescope tmux pane_file_paths
```

## Use with tmux display-popup
Tmux 3.2's new `display-popup` command is a neat way to access the telescope picker when you are outside of Neovim.

Add the following commands to your `.tmux.conf` which override the default tmux session and window pickers to use telescope.

note: if you use a dashboard you may need to add `tmp.txt` or a filename at the end of the `nvim` commands.
```
# use telescope-tmux for picking sessions and windows 
bind s display-popup -E -w 80% -h 80% nvim -c ":Telescope tmux sessions quit_on_select=true"
bind w display-popup -E -w 80% -h 80% nvim -c ":Telescope tmux windows quit_on_select=true"
# for contents searching
bind f display-popup -E -w 80% -h 80% nvim -c ":Telescope tmux pane_contents"
# and for quick file edits
bind f display-popup -E -w 80% -h 80% nvim -c ":Telescope tmux pane_file_paths"
```
