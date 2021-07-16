package.path = 'lua/telescope/_extensions/?.lua;' .. package.path

local action_state = require('telescope.actions.state')

describe("tmux windows", function()
  local windows = require'telescope._extensions.tmux.windows'

  it("correctly handle duplicate window names in the same session", function()
    local window_name = "window1"
    local window_id1 = "1:1"
    local window_id2 = "1:2"
    local tmux_commands = require'telescope._extensions.tmux.tmux_commands'
    tmux_commands.list_windows = function(opts)
      if opts.format == tmux_commands.window_id_fmt then
        return {window_id1, window_id2}
      end
      return {window_name, window_name}
    end

    windows({})
    local prompt_bufnr = vim.api.nvim_win_get_buf(0)
    local picker = action_state.get_current_picker(prompt_bufnr)
    local results = picker.finder.results
    assert.equals(results[1].value, window_id1)
    assert.equals(results[2].value, window_id2)
  end)
end)
