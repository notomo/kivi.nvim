local kind_core = require "kivi/core/kind"
local listlib = require "kivi/lib/list"

local M = {}

local Executor = {}
Executor.__index = Executor

function Executor._action(self, kind, nodes, action_name, action_opts)
  local opts = action_opts or {}

  local action, action_err = kind:find_action(action_name, opts)
  if action_err ~= nil then
    return nil, action_err
  end

  return function(ctx)
    if action.behavior.quit then
      self.rendered_ui:close()
    end
    return action:execute(nodes, ctx)
  end, nil
end

function Executor.execute(self, ctx, all_nodes, action_name, action_opts)
  local cache = {}
  local kinds = {}
  for _, node in ipairs(all_nodes) do
    local kind_name = node.kind_name or self.kind_name
    if cache[kind_name] == nil then
      local kind, err = kind_core.create(self, kind_name, action_name)
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

function Executor.rename(self, items)
  local kind, err = kind_core.create(self, self.kind_name, nil)
  if err ~= nil then
    return nil, err
  end
  return kind:rename(items)
end

M.create = function(notifier, ui)
  local tbl = {
    notifier = notifier,
    ui = ui,
    source_name = ui.source.name,
    kind_name = ui.source.kind_name,
  }
  return setmetatable(tbl, Executor)
end

return M
