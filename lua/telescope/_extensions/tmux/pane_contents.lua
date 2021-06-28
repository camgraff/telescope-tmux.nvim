local utils = require('telescope.utils')

local pane_contents = {}

local ns_id = vim.api.nvim_create_namespace('telescope-tmux.previewers')

local function is_buf_empty(bufid)
    local line_count = vim.api.nvim_buf_line_count(bufid)
    local first_line = vim.api.nvim_buf_get_lines(bufid, 0, 1, false)[1]
    return line_count == 1 and first_line == ''
end
pane_contents.define_preview = function(entry, winid, bufid, num_history_lines)
    local pane = entry.value.pane
    local line_num = entry.value.line_num
    vim.api.nvim_win_set_buf(winid, bufid)

    if is_buf_empty(bufid) then
        -- TODO: can we avoid this call and reuse the original capture-pane output?
        local pane_content = utils.get_os_command_output({'tmux', 'capture-pane', '-p', '-t', pane, '-S', -num_history_lines, '-e'})
        --local pane_content = {"one pane", "two pane", "three pane"}
        vim.api.nvim_win_set_option(winid, "number", false)
        vim.api.nvim_win_set_option(winid, "relativenumber", false)
        vim.api.nvim_win_set_option(winid, "wrap", false)

        -- TODO: check for nvim-terminal.lua and only include term escape codes if plugin is present
        vim.api.nvim_buf_set_option(bufid, "filetype", "terminal")
        vim.api.nvim_buf_set_lines(bufid, 0, -1, false, pane_content)
    end

    vim.api.nvim_buf_clear_namespace(bufid, ns_id, 0, -1)
    vim.api.nvim_buf_add_highlight(bufid, ns_id, "TelescopePreviewLine", line_num-1, 0, -1)
    vim.api.nvim_win_set_cursor(winid, {line_num, 0})
end

pane_contents.list_panes = function()
    local raw_panes =  utils.get_os_command_output({'tmux', 'list-panes', '-a', '-F', '#{pane_id}\t#{session_name}\t'})
    local panes = {}
    for _, pane in ipairs(raw_panes) do
        local it = string.gmatch(pane, "[^\t]*\t")
        local id = it():sub(1, -2)
        local session = it():sub(1, -2)
        table.insert(panes, {id=id, session=session})
    end
    return panes
end

pane_contents.get_current_pane_id = function()
    return utils.get_os_command_output({'tmux', 'display-message', '-p', '#{pane_id}'})[1]
end

return pane_contents
