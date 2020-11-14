local listlib = require "kivi/lib/list"
local Kind = require("kivi/core/kind").Kind

local M = {}

local Executor = {}
Executor.__index = Executor
M.Executor = Executor

function Executor.new(starter, ui, source)
  local tbl = {_ui = ui, _kind_name = source.kind_name, _starter = starter}
  return setmetatable(tbl, Executor)
end

function Executor._action(self, kind, nodes, action_name, action_opts)
  local opts = action_opts or {}

  local action, action_err = kind:find_action(action_name, opts)
  if action_err ~= nil then
    return nil, action_err
  end

  return function(ctx)
    if action.behavior.quit then
      self._ui:close()
    end
    return action:execute(nodes, ctx)
  end, nil
end

function Executor.execute(self, ctx, all_nodes, action_name, action_opts)
  local cache = {}
  local kinds = {}
  for _, node in ipairs(all_nodes) do
    local kind_name = node.kind_name or self._kind_name
    if cache[kind_name] == nil then
      local kind, err = Kind.new(self._starter, kind_name)
      if err ~= nil then
        return nil, err
      end
      cache[kind_name] = kind
    end
    kinds[node.path] = cache[kind_name]
  end

  local node_groups = listlib.group_by(all_nodes, function(node)
    return kinds[node.path]
  end)

  local result
  for _, node_group in ipairs(node_groups) do
    local kind, nodes = unpack(node_group)
    local action, action_err = self:_action(kind, nodes, action_name, action_opts)
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
