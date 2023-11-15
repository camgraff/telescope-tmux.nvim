local pane_contents = require("telescope._extensions.tmux.pane_contents")

return require("telescope").register_extension({
    exports = {
        sessions = require("telescope._extensions.tmux.sessions"),
        windows = require("telescope._extensions.tmux.windows"),
        pane_contents = pane_contents.cmd,
        pane_file_paths = pane_contents.file_paths_cmd,
    },
})
