local Promise = require("kivi.vendor.promise")

local ActionContext = {}

function ActionContext.new(kind, action_opts)
  local tbl = {
    kind = kind,
    opts = action_opts,
  }
  return setmetatable(tbl, ActionContext)
end

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
  local action_ctx = ActionContext.new(self._kind, self.action_opts)
  local result, err = self._action(self, nodes, action_ctx, ctx)
  if err then
    return Promise.reject(err)
  end
  return Promise.resolve(result)
end

function Action.is_same(self, action)
  return self._action == action._action
end

return Action
