local M = {}

local Action = {}
M.Action = Action

function Action.new(kind, fn, action_opts, behavior)
  vim.validate({
    kind = {kind, "table"},
    fn = {fn, "function"},
    action_opts = {action_opts, "table"},
    behavior = {behavior, "table"},
  })
  local tbl = {action_opts = action_opts, behavior = behavior, _kind = kind, _fn = fn}
  return setmetatable(tbl, Action)
end

function Action.__index(self, k)
  return rawget(Action, k) or self._kind[k]
end

function Action.execute(self, nodes, ctx)
  return self._fn(self, nodes, ctx)
end

return M
