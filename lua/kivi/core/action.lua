local M = {}

local Action = {}
Action.__index = Action
M.Action = Action

function Action.new(kind, fn, action_opts, behavior)
  kind.__index = kind
  local tbl = {action_opts = action_opts, behavior = behavior}
  local action = setmetatable(tbl, kind)

  action.execute = function(self, nodes, ctx)
    return fn(self, nodes, ctx)
  end

  return action
end

return M
