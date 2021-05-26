local M = {}

local Executor = {}
Executor.__index = Executor
M.Executor = Executor

function Executor.new(ui)
  local tbl = {_ui = ui}
  return setmetatable(tbl, Executor)
end

function Executor._action(self, kind, nodes, action_name, opts, action_opts)
  action_opts = action_opts or {}

  local action, action_err = kind:find_action(action_name, action_opts)
  if action_err ~= nil then
    return nil, action_err
  end

  return function(ctx)
    local result, err = action:execute(nodes, ctx)
    if opts.quit then
      self._ui:close()
    end
    return result, err
  end, nil
end

function Executor.execute(self, ctx, all_nodes, action_name, opts, action_opts)
  local result
  for kind, nodes in all_nodes:group_by_kind() do
    local action, action_err = self:_action(kind, nodes, action_name, opts, action_opts)
    if action_err ~= nil then
      return nil, action_err
    end

    local res, err = action(ctx)
    if err ~= nil then
      return nil, err
    end
    result = res
  end
  return result, nil
end

return M
