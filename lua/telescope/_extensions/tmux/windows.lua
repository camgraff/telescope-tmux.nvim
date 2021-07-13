local tutils = require('telescope.utils')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local sorters = require('telescope.sorters')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local previewers = require('telescope.previewers')
local utils = require'telescope._extensions.tmux.utils'

-- TODO: Passing entire opts may not be a good idea since -f can change what windows appear in the table
local function get_windows(opts)
    local sessions = tutils.get_os_command_output({ 'tmux', 'list-windows', unpack(opts) })
    return sessions
end

local windows = function(opts)
    opts = utils.apply_default_layout(opts)
    -- We have to include the session here since we show the preview by linking a window.
    -- If we attempt to attach using solely the window id, it is ambiguous because the window is linked
    -- between the real session and the dummy session used for previewing.
    local window_ids = get_windows({"-a", '-F', '#S:#{window_id}'})
    -- TODO: These should be able to be passed by the user
    local windows_with_user_opts = get_windows({"-a", '-F', '#S: #W'})

    local custom_to_default_map = {}
    for i, v in ipairs(windows_with_user_opts) do
        custom_to_default_map[v] = window_ids[i]
    end

    -- FIXME: This command can display a session name even if you are in a seperate terminal session that isn't using tmux
    local current_window = tutils.get_os_command_output({'tmux', 'display-message', '-p', '#S:#{window_id}'})[1]
    local dummy_session_name = "telescope-tmux-previewer"

    local current_client = tutils.get_os_command_output({'tmux', 'display-message', '-p', '#{client_tty}'})[1]

    pickers.new(opts, {
        prompt_title = 'Tmux Windows',
        finder = finders.new_table {
            results = windows_with_user_opts,
            entry_maker = function(result)
                return {
                    value = result,
                    display = result,
                    ordinal = result,
                    valid = custom_to_default_map[result] ~=  current_window
                }
            end
        },
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
                local window_id = custom_to_default_map[entry.value]
                vim.api.nvim_buf_call(self.state.bufnr, function()
                    -- kil the job running in previous previewer
                    if tutils.job_is_running(self.state.termopen_id) then vim.fn.jobstop(self.state.termopen_id) end
                    vim.cmd(string.format("silent !tmux link-window -s %s -t %s:0 -kd", window_id, dummy_session_name))
                    -- Need -r here to prevent resizing the window which will distort the view on the real client
                    self.state.termopen_id = vim.fn.termopen(string.format("tmux attach -t %s -r", dummy_session_name))
                end)
            end,
            teardown = function(self)
                vim.api.nvim_command(string.format("silent !tmux kill-session -t %s", dummy_session_name))
            end
        }),
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                local selected_window_id = custom_to_default_map[selection.value]
                vim.cmd(string.format('silent !tmux switchc -t %s -c %s', selected_window_id, current_client))
                actions.close(prompt_bufnr)
            end)
            actions.close:enhance({
                post = function ()
                    if opts.quit_on_select then
                        vim.cmd('q')
                    end
                end
            })
            return true
        end
    }):find()
end

return windows

