# Telescope-tmux.nvim

A Telescope.nvim extension for fuzzy-finding over tmux targets.

![demo](https://i.imgur.com/WvSXmaI.gif)

## Prerequisites

- [Neovim nightly](https://github.com/neovim/neovim/releases/tag/nightly)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [tmux](https://github.com/tmux/tmux)

## Commands

### Sessions
```
:Telescope tmux sessions
```

### Windows
```
:Telescope tmux windows
```

### Pane Contents
```
:Telescope tmux pane_contents
```

## Use with tmux display-popup
Tmux 3.2's new `display-popup` command is a neat way to access the telescope picker when you are outside of Neovim.

Add the following commands to your `.tmux.conf` which override the default tmux session and window pickers to use telescope.
```
# use telescope-tmux for picking sessions and windows 
bind s display-popup -E -w 80% -h 80% nvim -c ":Telescope tmux sessions quit_on_select=true"
bind w display-popup -E -w 80% -h 80% nvim -c ":Telescope tmux windows quit_on_select=true"
```

Better docs and more features coming so[on?]meday!
