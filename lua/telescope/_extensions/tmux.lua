local telescope = require('telescope')
local utils = require('telescope.utils')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local sorters = require('telescope.sorters')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local previewers = require('telescope.previewers')

local pane_contents = require'telescope._extensions.tmux.pane_contents'

local pane_contents_cmd = function(opts)
    local panes = pane_contents.list_panes()
    local current_pane = pane_contents.get_current_pane_id()
    local num_history_lines = opts.max_history_lines or 10000
    local results = {}
    for _, pane in ipairs(panes) do
        local pane_id = pane.id
        local session = pane.session
        local contents = utils.get_os_command_output({'tmux', 'capture-pane', '-p', '-t', pane_id, '-S', -num_history_lines})
        for i, line in ipairs(contents) do
            table.insert(results, {pane=pane_id, session=session, line=line, line_num=i})
        end
    end

    pickers.new(opts, {
        prompt_title = 'Tmux Pane Contents',
        finder = finders.new_table {
            results = results,
            entry_maker = function(result)
                return {
                    value = {
                        pane = result.pane,
                        line_num = result.line_num,
                    },
                    -- TODO: make the display prefix prettier
                    display = result.session .. ":" .. result.pane .. " " .. result.line,
                    ordinal = result.line,
                    valid = result.pane ~= current_pane
                }
            end
        },
        sorter = sorters.get_generic_fuzzy_sorter(),
        -- would prefer to use this when https://github.com/neovim/neovim/issues/14557 is fixed.
        previewer = previewers.new_buffer_previewer({
            define_preview = function(self, entry, status)
                pane_contents.define_preview(entry, self.state.winid, self.state.bufnr, num_history_lines)
            end,
            get_buffer_by_name = function (self, entry)
                return entry.value.pane
            end
        }),
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                local pane = selection.value.pane
                local line_num = selection.value.line_num
                actions.close(prompt_bufnr)
                vim.api.nvim_command("silent !tmux copy-mode -t \\" .. pane)
                vim.api.nvim_command(string.format('silent !tmux send-keys -t \\%s -X history-top', pane))
                vim.api.nvim_command(string.format('silent !tmux send-keys -t \\%s -X -N %s cursor-down', pane, line_num-1))
                vim.api.nvim_command(string.format('silent !tmux send-keys -t \\%s -X select-line', pane))
                -- pane IDs start with % so have to escape it
                vim.api.nvim_command('silent !tmux switchc -t \\' .. pane)
            end)

            return true
        end
    }):find()
end


return telescope.register_extension {
    exports = {
        --sessions = sessions,
        sessions = require'telescope._extensions.tmux.sessions',
        windows = require'telescope._extensions.tmux.windows',
        pane_contents = pane_contents_cmd,
    }
}
