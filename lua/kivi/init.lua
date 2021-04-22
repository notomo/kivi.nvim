local Command = require("kivi.command").Command

local M = {}

function M.open(source_name, opts)
  return Command.new("open", source_name, opts)
end

function M.execute(action_name, opts, action_opts)
  return Command.new("execute", action_name, opts, action_opts)
end

function M.is_parent()
  return Command.new("is_parent")
end

return M
