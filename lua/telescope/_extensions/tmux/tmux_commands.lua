local tutils = require('telescope.utils')

local tmux_commands = {}

-- Include the session name since the window may be linked to multiple sessions
-- This format makes the window location unambiguous
tmux_commands.window_id_fmt = "#{session_name}:#{window_id}"

tmux_commands.list_windows = function(opts)
  local cmd = {'tmux', 'list-windows', '-a'}
  if opts.format ~= nil then
    table.insert(cmd, "-F")
    table.insert(cmd, opts.format)
  end
  return tutils.get_os_command_output(cmd)
end

tmux_commands.get_base_index_option = function()
  return tutils.get_os_command_output{'tmux', 'show-options', '-gv', 'base-index'}[1]
end

tmux_commands.link_window = function(src_window, target_window)
  local src = src_window  or error("src_window is required")
  local target = target_window  or error("target_window is required")
  return tutils.get_os_command_output{'tmux', 'link-window', "-kd", '-s', src, "-t", target}
end


return tmux_commands
