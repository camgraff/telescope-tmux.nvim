package.path = 'lua/telescope/_extensions/?.lua;' .. package.path

local tmux = require'tmux'.exports
local mock = require('luassert.mock')

describe("pane_contents", function()
  it("should display pane contents with correct line numbering", function()
      local pane = "%1"
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
    local bufid = vim.api.nvim_get_current_buf()
    local utils = mock(require('telescope.utils'), true)
    utils.get_os_command_output.returns{line}

    tmux.display_pane_content_preview(entry, winid, bufid, {}, 100)
    vim.wait(100)
    local actual_line = vim.api.nvim_buf_get_lines(bufid, 1, 2, true)[1]
    assert.equals(line, actual_line)


  end)
end)
