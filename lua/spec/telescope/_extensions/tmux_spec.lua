local tmux = require'telescope._extensions.tmux'
local tester = require('telescope.pickers._test')
local mock = require('luassert.mock')

describe("some basics", function()
  local bello = function(boo)
    return "bello " .. boo
  end

  local bounter

  before_each(function()
    bounter = 0
  end)

  -- This works if you don't run in headless mode.. hmmmm
  it("some test", function()
    local some_func = mock(function() end, true)
    tmux.exports.windows({some_func = some_func, on_complete = {coroutine.wrap(function()
        print("COMPLETE")
        vim.api.nvim_feedkeys("j", "t", true)
        vim.wait(10)
        vim.defer_fn(function ()
            local enter = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
            vim.api.nvim_feedkeys(enter, "t", true)
        end, 40)
        coroutine.yield()
    end)}})
    vim.wait(100)
    assert.stub(some_func).was_called()
    --vim.cmd("Telescope tmux windows")
    --vim.wait(100)
    --vim.wait(100)
    --print(vim.inspect(vim.api.nvim_list_wins()))
    --bounter = 100
  end)

  --it("some other test", function()
    --assert.equals(0, bounter)
  --end)

  --it('should find the pickers.lua', function()
    --tester.run_string [[
      --tester.builtin_picker('find_files', 'tmux.lua', {
      --})
    --]]
  --end)
end)
