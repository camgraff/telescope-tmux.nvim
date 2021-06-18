local tmux = require'telescope._extensions.tmux'
local tester = require('telescope.pickers._test')
local mock = require('luassert.mock')
local functional = require "plenary.functional"
local uv = require "luv"
local util = require "plenary.async.util"
--local a = require('plenary.async')
local a = require('plenary.async')

describe("some basics", function()
  it("some test", function()
    local some_func = mock(function() end, true)
    local finished = false
    --vim.cmd("Telescope tmux windows")
    --vim.wait(1000)
    --vim.cmd('lua vim.defer_fn(function() vim.fn.feedkeys(vim.api.nvim_replace_termcodes("joplin<CR>", 1, 1, 1)) end, 2000)')
    --local co = coroutine.create(function()
    local timer = uv.new_timer()
        --local s = vim.defer_fn(function ()
        --end, 1000)
    --vim.loop.run()
    --print(finished)
    --print(uv.run("nowait"))
    --uv.sleep(2000)
    --vim.wait(5000, function() return finished end, 100, false)
    --util.block_on(function()
        --timer:start(2000, 0, function()
            --vim.schedule(function()
                --vim.fn.feedkeys(vim.api.nvim_replace_termcodes("joplin<CR>", true, true, true))
                --print("ASSERTED")
                --timer:close()
                --finished = true
            --end)
        --end)
        --a.util.sleep(2000)
    --end)
    local condvar = a.control.Condvar.new()
    util.block_on(function()
        --local s = vim.defer_fn(function()
        --if (vim.in_fast_event()) then
            --print("in fast")
            --a.util.scheduler()
        --end
        vim.schedule_wrap(function()
            tmux.exports.windows({ some_func = some_func })
            vim.fn.feedkeys(vim.api.nvim_replace_termcodes("joplin<CR>", true, true, true))
            print("ASSERTED")
            --timer:close()
            finished = true
            print("done")
            vim.wait(2000)
            --util.sleep(100)
            condvar:notify_one()
        end)()

        condvar:wait()
        print("waiting")
    end, 10000)
    assert.stub(some_func).was_called()
        --timer:start(2000, 0, function()
            --vim.schedule(function()
                --vim.fn.feedkeys(vim.api.nvim_replace_termcodes("joplin<CR>", true, true, true))
                --print("ASSERTED")
                --timer:close()
                --finished = true
            --end)
        --end)
    --end))

    --assert.stub(some_func).was_called()
        --end, 2000)
        --coroutine.yield()
    --end)
    --coroutine.yield()
    --coroutine.resume(co)
    --assert.stub(some_func).was_called()
    --vim.api.nvim_feedkeys("j", "t", true)
    --vim.api.nvim_feedkeys(enter, "t", true)
    --vim.wait(1000)
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
