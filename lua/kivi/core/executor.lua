local M = {}

--- @param ctx KiviContext
--- @param all_nodes KiviNodes
function M.execute(ctx, all_nodes, action_name, opts, action_opts)
  action_opts = action_opts or {}

  local holders = {}

  local iter = all_nodes:group_by_kind()
  if type(iter) == "string" then
    local err = iter
    return err
  end

  for kind, nodes in iter do
    local action = kind:find_action(action_name, action_opts)
    if type(action) == "string" then
      local err = action
      return err
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
    local res = holder.action:execute(holder.nodes, ctx)
    if opts.quit then
      ctx.ui:close()
    end
    result = res
  end
  return result
end

return M
