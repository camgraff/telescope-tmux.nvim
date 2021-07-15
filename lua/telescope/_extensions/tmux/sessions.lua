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
            local new_session_id = tutils.get_os_command_output{"tmux", "new-session", "-dP", "-s", new_session, "-F", "#{session_id}"}[1]
            tutils.get_os_command_output{"tmux", "switch-client", "-t", new_session_id, "-c", current_client}
            actions.close(prompt_bufnr)
        end,
        delete_session = function(prompt_bufnr)
            local entry = action_state.get_selected_entry()
            local session_id = entry.value
            local session_display = entry.display
            local confirmation = vim.fn.input("Kill session '" .. session_display .. "'? [Y/n] ")
            if string.lower(confirmation) ~= 'y' then return end
            tutils.get_os_command_output{"tmux", "kill-session", "-t", session_id}
            actions.close(prompt_bufnr)
        end,
        rename_session = function(prompt_bufnr)
            local session = action_state.get_selected_entry().value
            local new_session_name = vim.fn.input("Enter new session name: ")
            if string.lower(new_session_name) == '' then return end
            tutils.get_os_command_output{"tmux", "rename-session", "-t", session, new_session_name}
            actions.close(prompt_bufnr)
        end,
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
            map('i', '<c-d>', custom_actions.delete_session)
            map('n', '<c-d>', custom_actions.delete_session)
            map('i', '<c-r>', custom_actions.rename_session)
            map('n', '<c-r>', custom_actions.rename_session)

            return true
        end,
    }):find()
end

return sessions
