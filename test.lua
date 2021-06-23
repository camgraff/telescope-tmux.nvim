local telescope = require('telescope')
local utils = require('telescope.utils')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local sorters = require('telescope.sorters')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local previewers = require('telescope.previewers')
local transform_mod = require('telescope.actions.mt').transform_mod

local ns_previewer = vim.api.nvim_create_namespace('telescope-tmux.previewers')

display_pane_content_preview = function(entry, winid, bufid, buf_cache, num_history_lines)
    local pane = entry.value.pane
    local line_num = entry.value.line_num
    -- TODO: can we avoid this call and reuse the original capture-pane output?
    --local pane_content = utils.get_os_command_output({'tmux', 'capture-pane', '-p', '-t', pane, '-S', -num_history_lines, '-Ne'})
    local pane_content = vim.fn.readfile("tmux_out")
    --vim.fn.writefile(pane_content, "tmux_out_utils")
    vim.api.nvim_win_set_option(winid, "wrap", false)

    if buf_cache[pane] == nil then
        local chan_id = vim.api.nvim_open_term(bufid, {})
        for i, line in ipairs(pane_content)  do
            print(line)
            vim.fn.chansend(chan_id, line .. "\r\n")
        end
        vim.fn.chanclose(chan_id)
        -- Not sure if this is helpful/necessary?
        vim.fn.jobwait({chan_id})
        buf_cache[pane] = bufid
    end

    vim.api.nvim_buf_clear_namespace(bufid, ns_previewer, 0, -1)
    vim.api.nvim_win_set_cursor(winid, {line_num, 0})
    vim.api.nvim_win_set_buf(winid, bufid)
    vim.cmd("norm! zz")
    vim.api.nvim_buf_add_highlight(bufid, ns_previewer, "TelescopePreviewLine", line_num, 0, -1)
end

local pane = "%4"
local line_num = 2
local line = "here is a line to display"
local entry = {
  value = {
      pane = pane,
      line_num = line_num,
  },
  -- TODO: make the display prefix prettier
  display = pane .. ":" .. line_num .. ": " .. line,
  ordinal = line,
  valid = true
}
local winid = vim.api.nvim_get_current_win()
local bufid = vim.api.nvim_create_buf(true, true)

display_pane_content_preview(entry, winid, bufid, {}, 10000)
