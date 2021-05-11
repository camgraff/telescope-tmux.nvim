local telescope = require('telescope')
local utils = require('telescope.utils')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local sorters = require('telescope.sorters')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local previewers = require('telescope.previewers')

-- TODO: It is better to pass an opts table and allow any additional options for the command
local function get_sessions(format)
    return utils.get_os_command_output({ 'tmux', 'list-sessions', '-F', format })
end

-- TODO: Passing entire opts may not be a good idea since -f can change what windows appear in the table
local function get_windows(opts)
    local sessions = utils.get_os_command_output({ 'tmux', 'list-windows', unpack(opts) })
    return sessions
end

-- Do this by linking windows
local windows = function(opts)
    local window_ids = get_windows({"-a", '-F', '#{window_id}'})
    -- TODO: These should be able to be passed by the user
    local windows_with_user_opts = get_windows({"-a", '-F', '#S: #W'})

    local custom_to_default_map = {}
    for i, v in ipairs(windows_with_user_opts) do
        custom_to_default_map[v] = window_ids[i]
    end

    -- FIXME: This command can display a session name even if you are in a seperate terminal session that isn't using tmux
    local current_window = utils.get_os_command_output({'tmux', 'display-message', '-p', '#{window_id}'})[1]
    local dummy_session_name = "telescope-tmux-previewer"

    pickers.new(opts, {
        prompt_title = 'Tmux Windows',
        finder = finders.new_table {
            results = windows_with_user_opts
        },
        sorter = sorters.get_generic_fuzzy_sorter(),
        previewer = previewers.new_buffer_previewer({
            setup = function(self)
                vim.api.nvim_command(string.format("!tmux new-session -s %s -d", dummy_session_name))
                return {}
            end,
            define_preview = function(self, entry, status)
                local window_id = custom_to_default_map[entry[1]]
                -- Can't attach to current session otherwise neovim will freak out
                if current_window == window_id then
                    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {"Currently attached to this session."})
                else
                    vim.api.nvim_buf_call(self.state.bufnr, function()
                        utils.get_os_command_output({"tmux", "link-window", "-s", window_id, "-t", dummy_session_name .. ":0", "-k"})
                        -- Need -r here to prevent resizing the window to fix in the preview buffer
                        vim.fn.termopen(string.format("tmux attach -t %s -r", dummy_session_name))
                    end)
                end
            end,
            teardown = function(self)
                vim.api.nvim_command(string.format("silent !tmux kill-session -t %s", dummy_session_name))
            end
        }),
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                vim.api.nvim_command('silent !tmux switchc -t ' .. custom_to_default_map[selection.value])
            end)

            return true
        end
    }):find()
end


local sessions = function(opts)
    -- TODO: Use session IDs instead of names
    local session_names = get_sessions('#S')
    local user_formatted_session_names = get_sessions(opts.format or '#S')
    local formatted_to_real_session_map = {}
    for i, v in ipairs(user_formatted_session_names) do
        formatted_to_real_session_map[v] = session_names[i]
    end

    -- FIXME: This command can display a session name even if you are in a seperate terminal session that isn't using tmux
    local current_session = utils.get_os_command_output({'tmux', 'display-message', '-p', '#S'})[1]

    pickers.new(opts, {
        prompt_title = 'Tmux Sessions',
        finder = finders.new_table {
            results = user_formatted_session_names
        },
        sorter = sorters.get_generic_fuzzy_sorter(),
        previewer = previewers.new_buffer_previewer({
            define_preview = function(self, entry, status)
                local session_name = formatted_to_real_session_map[entry[1]]
                -- Can't attach to current session otherwise neovim will freak out
                if current_session == session_name then
                    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {"Currently attached to this session."})
                else
                    vim.api.nvim_buf_call(self.state.bufnr, function()
                        vim.fn.termopen(string.format("tmux attach -t %s -r", session_name))
                    end)
                end
            end
        }),
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                vim.api.nvim_command('silent !tmux switchc -t ' .. selection.value)
            end)

            return true
        end,
    }):find()
end

return telescope.register_extension {
    exports = {
        sessions = sessions,
        windows = windows
    }
}
