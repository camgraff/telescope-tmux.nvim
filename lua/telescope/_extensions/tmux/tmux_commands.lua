local tutils = require('telescope.utils')

local tmux_commands = {}

-- Include the session ID since the window may be linked to multiple sessions
-- This format makes the window location unambiguous
tmux_commands.window_id_fmt = "#{session_id}:#{window_id}"

tmux_commands.list_windows = function(opts)
  local cmd = {'tmux', 'list-windows', '-a'}
  if opts.format ~= nil then
    table.insert(cmd, "-F")
    table.insert(cmd, opts.format)
  end
  return tutils.get_os_command_output(cmd)
end


return tmux_commands
