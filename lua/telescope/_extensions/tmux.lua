local telescope = require('telescope')
local utils = require('telescope.utils')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local sorters = require('telescope.sorters')
local make_entry = require('telescope.make_entry')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local previewers = require('telescope.previewers')

local function get_tmux_sessions()
    local sessions = utils.get_os_command_output({ 'tmux', 'list-sessions', '-F', '#{session_name}' })
    return sessions
end


local sessions = function(opts)
    opts = opts or {}
      --opts.entry_maker = opts.entry_maker or entry_maker_gen_from_active_sessions(opts)

    local results = get_tmux_sessions()
    -- FIXME: This command can display a session name even if you are in a seperate terminal session that isn't using tmux
    local current_session = utils.get_os_command_output({'tmux', 'display-message', '-p', '#S'})[1]

    pickers.new(opts, {
        prompt_title = 'Tmux Sessions',
        finder = finders.new_table(results),
        sorter = sorters.get_generic_fuzzy_sorter(),
        previewer = previewers.new_buffer_previewer({
            define_preview = function(self, entry, status)
                local session_name = entry[1]
                -- Can't attach to current session otherwise neovim will freak out
                if current_session == session_name then
                    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {"Currently attached to this session."})
                else
                    vim.api.nvim_buf_call(self.state.bufnr, function()
                        -- atach to tmux session here
                        vim.fn.termopen(string.format("tmux attach -t %s", session_name))
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
        sessions = sessions
    }
}
