local utils = require("telescope.utils")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local sorters = require("telescope.sorters")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

local pane_contents = {}

local ns_id = vim.api.nvim_create_namespace("telescope-tmux.previewers")

local function is_buf_empty(bufid)
    local line_count = vim.api.nvim_buf_line_count(bufid)
    local first_line = vim.api.nvim_buf_get_lines(bufid, 0, 1, false)[1]
    return line_count == 1 and first_line == ""
end
pane_contents.define_preview = function(entry, winid, bufid, num_history_lines)
    local pane = entry.value.pane
    local line_num = entry.value.line_num
    vim.api.nvim_win_set_buf(winid, bufid)

    if is_buf_empty(bufid) then
        -- TODO: can we avoid this call and reuse the original capture-pane output?
        local pane_content =
            utils.get_os_command_output({ "tmux", "capture-pane", "-p", "-t", pane, "-S", -num_history_lines, "-e" })
        --local pane_content = {"one pane", "two pane", "three pane"}
        vim.api.nvim_win_set_option(winid, "number", false)
        vim.api.nvim_win_set_option(winid, "relativenumber", false)
        vim.api.nvim_win_set_option(winid, "wrap", false)

        -- TODO: check for nvim-terminal.lua and only include term escape codes if plugin is present
        vim.api.nvim_buf_set_option(bufid, "filetype", "terminal")
        vim.api.nvim_buf_set_lines(bufid, 0, -1, false, pane_content)
    end

    vim.api.nvim_buf_clear_namespace(bufid, ns_id, 0, -1)
    vim.api.nvim_buf_add_highlight(bufid, ns_id, "TelescopePreviewLine", line_num - 1, 0, -1)
    vim.api.nvim_win_set_cursor(winid, { line_num, 0 })
end

pane_contents.list_panes = function()
    local raw_panes = utils.get_os_command_output({ "tmux", "list-panes", "-a", "-F", "#{pane_id}\t#{session_name}\t" })
    local panes = {}
    for _, pane in ipairs(raw_panes) do
        local it = string.gmatch(pane, "[^\t]*\t")
        local id = it():sub(1, -2)
        local session = it():sub(1, -2)
        table.insert(panes, { id = id, session = session })
    end
    return panes
end

pane_contents.get_current_pane_id = function()
    return utils.get_os_command_output({ "tmux", "display-message", "-p", "#{pane_id}" })[1]
end

pane_contents.cmd = function(opts)
    local panes = pane_contents.list_panes()
    local current_pane = pane_contents.get_current_pane_id()
    local num_history_lines = opts.max_history_lines or 10000
    local results = {}
    for _, pane in ipairs(panes) do
        local pane_id = pane.id
        local session = pane.session
        local contents =
            utils.get_os_command_output({ "tmux", "capture-pane", "-p", "-t", pane_id, "-S", -num_history_lines })
        for i, line in ipairs(contents) do
            table.insert(results, { pane = pane_id, session = session, line = line, line_num = i })
        end
    end

    pickers
        .new(opts, {
            prompt_title = "Tmux Pane Contents",
            finder = finders.new_table({
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
                        valid = result.pane ~= current_pane,
                    }
                end,
            }),
            sorter = sorters.get_generic_fuzzy_sorter(),
            -- would prefer to use this when https://github.com/neovim/neovim/issues/14557 is fixed.
            previewer = previewers.new_buffer_previewer({
                define_preview = function(self, entry, _)
                    pane_contents.define_preview(entry, self.state.winid, self.state.bufnr, num_history_lines)
                end,
                get_buffer_by_name = function(_, entry)
                    return entry.value.pane
                end,
            }),
            attach_mappings = function(prompt_bufnr)
                actions.select_default:replace(function()
                    local selection = action_state.get_selected_entry()
                    local pane = selection.value.pane
                    local line_num = selection.value.line_num
                    actions.close(prompt_bufnr)
                    vim.api.nvim_command("silent !tmux copy-mode -t \\" .. pane)
                    vim.api.nvim_command(string.format("silent !tmux send-keys -t \\%s -X history-top", pane))
                    vim.api.nvim_command(
                        string.format("silent !tmux send-keys -t \\%s -X -N %s cursor-down", pane, line_num - 1)
                    )
                    vim.api.nvim_command(string.format("silent !tmux send-keys -t \\%s -X select-line", pane))
                    -- pane IDs start with % so have to escape it
                    vim.api.nvim_command("silent !tmux switchc -t \\" .. pane)
                end)

                return true
            end,
        })
        :find()
end

pane_contents.file_paths_cmd = function(opts)
    local Path = require("plenary.path")
    local panes = pane_contents.list_panes()
    local current_pane = utils.get_os_command_output({ "echo", "${TMUX_PANE}" })
    local num_history_lines = opts.max_history_lines or 10000
    local grep_cmd = opts.grep_cmd or "grep -oP"
    -- regex to find paths and optional "line:col" at the end
    local regex = opts.regex or "(([.\\w\\-~\\$@]+)?(/?[\\w\\-@]+)+)\\.[a-zA-Z]\\w{0,5}(:\\d*:\\d*)?"
    local results = {}
    for _, pane in ipairs(panes) do
        local pane_id = pane.id
        if pane_id ~= current_pane then
            local pane_path = utils.get_os_command_output({
                "tmux",
                "display",
                "-pt",
                pane_id,
                "#{pane_current_path}",
            })[1] or ""
            local command_str = "tmux capture-pane -p -t "
                .. pane_id
                .. " -S "
                .. -num_history_lines
                .. " | "
                .. grep_cmd
                .. " '"
                .. regex
                .. "' | tr -d ' '"
            local contents = utils.get_os_command_output({
                "sh",
                "-c",
                command_str,
            })
            for _, line in ipairs(contents) do
                -- parse path, line, col
                local splits = {}
                local i = 1
                for part in string.gmatch(line, "[^:]+") do
                    splits[i] = part
                    i = i + 1
                end
                local path = Path:new(splits[1])
                if not path:is_absolute() then
                    path = Path:new(pane_path, path)
                end
                if path:is_file() then
                    local result = { path = path:normalize(), lnum = splits[2], cnum = splits[3] }
                    local key = result.path .. ":" .. (result.lnum or "") .. ":" .. (result.cnum or "")
                    if results[key] == nil then
                        results[key] = result
                    end
                end
            end
        end
    end

    local make_results = function()
        local values = {}
        for _, v in pairs(results) do
            table.insert(values, {
                path = v.path,
                lnum = tonumber(v.lnum),
                cnum = tonumber(v.cnum),
            })
        end
        return values
    end
    pickers
        .new(opts, {
            prompt_title = "Tmux Pane File Paths",
            finder = finders.new_table({
                results = make_results(),
                entry_maker = function(result)
                    local path = result.path
                    local line_num = result.lnum
                    local col_num = result.cnum
                    local line_col = ""
                    if line_num then
                        line_col = ":" .. line_num .. ":" .. col_num
                    end
                    return {
                        value = result,
                        filename = path,
                        lnum = line_num,
                        display = path .. line_col,
                        ordinal = path,
                    }
                end,
            }),
            sorter = sorters.get_generic_fuzzy_sorter(),
            previewer = require("telescope.config").values.grep_previewer(opts),
            attach_mappings = function(prompt_bufnr)
                actions.select_default:replace(function()
                    local selection = action_state.get_selected_entry()
                    actions.close(prompt_bufnr)
                    local path = selection.value.path
                    local line_num = selection.value.lnum
                    local col_num = selection.value.cnum
                    -- open up file
                    vim.cmd("e " .. path)
                    if line_num and col_num then
                        vim.api.nvim_call_function("cursor", { line_num, col_num })
                    end
                end)
                return true
            end,
        })
        :find()
end

return pane_contents
