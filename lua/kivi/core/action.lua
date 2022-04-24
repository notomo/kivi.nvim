local Promise = require("kivi.vendor.promise")

local Action = {}

local ACTION_PREFIX = "action_"

function Action.new(kind, name, action_opts)
  vim.validate({
    kind = { kind, "table" },
    name = { name, "string" },
    action_opts = { action_opts, "table" },
  })

  local action = kind[ACTION_PREFIX .. name]
  if not action then
    return nil, "not found action: " .. name
  end

  local tbl = {
    action_opts = vim.tbl_extend("force", kind.opts[name] or {}, action_opts),
    _kind = kind,
    _action = action,
  }
  return setmetatable(tbl, Action)
end

function Action.__index(self, k)
  return rawget(Action, k) or self._kind[k]
end

function Action.execute(self, nodes, ctx)
  local result, err = self._action(self, nodes, ctx)
  if err then
    return Promise.reject(err)
  end
  return Promise.resolve(result)
end

return Action
