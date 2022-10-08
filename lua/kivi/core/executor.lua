local Executor = {}
Executor.__index = Executor

function Executor.new(ui)
  local tbl = { _ui = ui }
  return setmetatable(tbl, Executor)
end

function Executor.execute(self, ctx, all_nodes, action_name, opts, action_opts)
  action_opts = action_opts or {}

  local holders = {}
  for kind, nodes in all_nodes:group_by_kind() do
    local action, err = kind:find_action(action_name, action_opts)
    if err then
      return nil, err
    end

    local previous = holders[#holders]
    if previous and previous.action:is_same(action) then
      vim.list_extend(previous.nodes, nodes)
    else
      table.insert(holders, {
        action = action,
        nodes = nodes,
      })
    end
  end

  local result = require("kivi.vendor.promise").resolve()
  for _, holder in ipairs(holders) do
    local res, err = holder.action:execute(holder.nodes, ctx)
    if opts.quit then
      self._ui:close()
    end
    if err ~= nil then
      return nil, err
    end
    result = res
  end
  return result, nil
end

return Executor
