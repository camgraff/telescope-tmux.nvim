local tutils = require('telescope.utils')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local sorters = require('telescope.sorters')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local previewers = require('telescope.previewers')
local transform_mod = require('telescope.actions.mt').transform_mod
local utils = require'telescope._extensions.tmux.utils'

local function get_sessions(format)
    return tutils.get_os_command_output({ 'tmux', 'list-sessions', '-F', format })
end

local sessions = function(opts)
    opts = utils.apply_default_layout(opts)
    -- TODO: Use session IDs instead of names
    local session_names = get_sessions('#S')
    local user_formatted_session_names = get_sessions(opts.format or '#S')
    local formatted_to_real_session_map = {}
    for i, v in ipairs(user_formatted_session_names) do
        formatted_to_real_session_map[v] = session_names[i]
    end

    -- FIXME: This command can display a session name even if you are in a seperate terminal session that isn't using tmux
    local current_session = tutils.get_os_command_output({'tmux', 'display-message', '-p', '#S'})[1]
    local current_client = tutils.get_os_command_output({'tmux', 'display-message', '-p', '#{client_tty}'})[1]

    local custom_actions = transform_mod({
        create_new_session = function(prompt_bufnr)
            local new_session = action_state.get_current_line()
            vim.cmd(string.format("silent !tmux new-session -d -s '%s'", new_session))
            vim.cmd(string.format("silent !tmux switchc -t '%s' -c %s", new_session, current_client))
            actions.close(prompt_bufnr)
        end
    })


    pickers.new(opts, {
        prompt_title = 'Tmux Sessions',
        finder = finders.new_table {
            results = user_formatted_session_names,
            entry_maker = function(result)
                return {
                    value = result,
                    display = result,
                    ordinal = result,
                    valid = formatted_to_real_session_map[result] ~=  current_session
                }
            end
        },
        sorter = sorters.get_generic_fuzzy_sorter(),
        previewer = previewers.new_termopen_previewer({
            get_command = function(entry, status)
                local session_name = formatted_to_real_session_map[entry.value]
                return {'tmux', 'attach-session', '-t', session_name, '-r'}
            end
        }),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                vim.cmd(string.format('silent !tmux switchc -t %s -c %s', selection.value, current_client))
                actions.close(prompt_bufnr)
            end)

            actions.close:enhance({
                post = function ()
                    if opts.quit_on_select then
                        vim.cmd('q!')
                    end
                end
            })

            map('i', '<c-a>', custom_actions.create_new_session)
            map('n', '<c-a>', custom_actions.create_new_session)

            return true
        end,
    }):find()
end

return sessions
