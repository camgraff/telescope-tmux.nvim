local tutils = require("telescope.utils")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local sorters = require("telescope.sorters")
local actions = require("telescope.actions")
local transform_mod = require("telescope.actions.mt").transform_mod
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")
local utils = require("telescope._extensions.tmux.utils")
local tmux_commands = require("telescope._extensions.tmux.tmux_commands")

local custom_actions = transform_mod({
    delete_window = function(prompt_bufnr)
        local entry = action_state.get_selected_entry()
        local window_id = entry.value
        local window_display = entry.display
        local confirmation = vim.fn.input("Kill window '" .. window_display .. "'? [Y/n] ")
        if string.lower(confirmation) ~= "y" then
            return
        end
        tmux_commands.kill_window(window_id)
        actions.close(prompt_bufnr)
    end,
})

local windows = function(opts)
    local list_windows = tmux_commands.list_windows
    opts = utils.apply_default_layout(opts)

    local window_ids = list_windows({ format = tmux_commands.window_id_fmt })
    local display_windows = list_windows({ format = opts.entry_format or "#S: #W" })
    -- FIXME: This command can display a session name even if you are in a seperate terminal session that isn't using tmux
    local current_window =
        tutils.get_os_command_output({ "tmux", "display-message", "-p", tmux_commands.window_id_fmt })[1]

    local entries = {}
    for i, v in ipairs(display_windows) do
        local entry = {
            value = window_ids[i],
            display = v,
            ordinal = v,
            valid = window_ids[i] ~= current_window,
        }
        table.insert(entries, entry)
    end

    local dummy_session_name = "telescope-tmux-previewer"
    local current_client = tutils.get_os_command_output({ "tmux", "display-message", "-p", "#{client_tty}" })[1]

    local base_index = tmux_commands.get_base_index_option()

    pickers
        .new(opts, {
            prompt_title = "Tmux Windows",
            finder = finders.new_table({
                results = entries,
                entry_maker = function(res)
                    return res
                end,
            }),
            sorter = sorters.get_generic_fuzzy_sorter(),
            previewer = previewers.new_buffer_previewer({
                setup = function(self)
                    vim.api.nvim_command(string.format("silent !tmux new-session -s %s -d", dummy_session_name))
                    return {}
                end,
                define_preview = function(self, entry, status)
                    -- We have to set the window buf manually to avoid a race condition where we try to attach to
                    -- the tmux sessions before the buffer has been set in the window. This is because Telescope
                    -- calls nvim_win_set_buf inside vim.schedule()
                    vim.api.nvim_win_set_buf(self.state.winid, self.state.bufnr)
                    local window_id = entry.value
                    vim.api.nvim_buf_call(self.state.bufnr, function()
                        -- kil the job running in previous previewer
                        if tutils.job_is_running(self.state.termopen_id) then
                            vim.fn.jobstop(self.state.termopen_id)
                        end
                        local target_window_id = dummy_session_name .. ":" .. base_index
                        tmux_commands.link_window(window_id, target_window_id)
                        -- Need -r here to prevent resizing the window which will distort the view on the real client
                        self.state.termopen_id =
                            vim.fn.termopen(string.format("tmux attach -t %s -r", dummy_session_name))
                    end)
                end,
                teardown = function(self)
                    vim.api.nvim_command(string.format("silent !tmux kill-session -t %s", dummy_session_name))
                end,
            }),
            attach_mappings = function(prompt_bufnr, map)
                actions.select_default:replace(function()
                    local selection = action_state.get_selected_entry()
                    local selected_window_id = selection.value
                    vim.cmd(string.format('silent !tmux switchc -t "%s" -c "%s"', selected_window_id, current_client))
                    actions.close(prompt_bufnr)
                end)
                actions.close:enhance({
                    post = function()
                        if opts.quit_on_select then
                            vim.cmd("q")
                        end
                    end,
                })
                map("i", "<c-d>", custom_actions.delete_window)
                map("n", "<c-d>", custom_actions.delete_window)
                return true
            end,
        })
        :find()
end

return windows
