local Command = require("kivi.command").Command

local M = {}

function M.open(opts)
  return Command.new("open", opts)
end

function M.execute(action_name, opts, action_opts)
  return Command.new("execute", action_name, opts, action_opts)
end

function M.setup(config)
  return Command.new("setup", config)
end

function M.is_parent()
  return Command.new("is_parent")
end

return M
