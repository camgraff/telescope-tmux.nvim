local has_telescope, telescope = pcall(require, 'telescope')
if not has_telescope then
  error('This plugins requires nvim-telescope/telescope.nvim')
end

local utils = require('telescope.utils')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local sorters = require('telescope.sorters')
local make_entry = require('telescope.make_entry')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

local function get_tmux_sessions()
    local sessions = utils.get_os_command_output({ 'tmux', 'list-sessions', '-F', '#{session_name}' })
    return sessions
end



local sessions = function(opts)
    opts = opts or {}
      --opts.entry_maker = opts.entry_maker or entry_maker_gen_from_active_sessions(opts)

    local results = get_tmux_sessions()
    print(results)

    pickers.new(opts, {
        prompt_title = 'Tmux Sessions',
        finder = finders.new_table(results),
        sorter = sorters.get_generic_fuzzy_sorter(),
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                print(selection.value)
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
