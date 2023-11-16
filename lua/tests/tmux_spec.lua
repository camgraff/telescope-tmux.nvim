package.path = "lua/telescope/_extensions/?.lua;" .. package.path

local mock = require("luassert.mock")

describe("pane_contents", function()
    local pane_contents = require("telescope._extensions.tmux.pane_contents")

    it("should display pane contents with correct line numbering", function()
        local pane = "%1"
        local line_num = 1
        local line = "here is a line to display"
        local entry = {
            value = {
                pane = pane,
                line_num = line_num,
            },
            -- TODO: make the display prefix prettier
            display = pane .. ":" .. line_num .. ": " .. line,
            ordinal = line,
            valid = true,
        }
        local winid = vim.api.nvim_get_current_win()
        local bufid = vim.api.nvim_create_buf(true, true)
        local utils = mock(require("telescope.utils"), true)
        utils.get_os_command_output.returns({ line })

        pane_contents.define_preview(entry, winid, bufid, 100)
        vim.wait(100)
        local actual_line = vim.api.nvim_buf_get_lines(bufid, line_num - 1, line_num, true)[1]
        assert.equals(line, actual_line)
    end)

    it("should correctly display tmux capture-pane output with terminal escape codes", function()
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
            valid = true,
        }
        local winid = vim.api.nvim_get_current_win()
        local bufid = vim.api.nvim_create_buf(true, true)
        local utils = mock(require("telescope.utils"), true)
        local lines = vim.fn.readfile("lua/tests/fixtures/pane_contents_output.txt")
        utils.get_os_command_output.returns(lines)

        pane_contents.define_preview(entry, winid, bufid, 100)
        vim.wait(100)
        local actual_line = vim.api.nvim_buf_get_lines(bufid, line_num - 1, line_num, true)[1]
        local expected =
            "[38;2;80;73;69m~                              [38;2;102;92;84m│[38;2;124;111;100m    [38;2;235;219;178missues https://github.com/syncthing/syncthing/issues/6252. Also some remnance here https://github.com/gsantner/markor/issues/954#issuecomment-700337136                "
        assert.equals(expected, actual_line)
    end)
end)
