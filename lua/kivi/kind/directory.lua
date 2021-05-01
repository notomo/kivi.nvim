local M = {}

function M.action_open(self, nodes, ctx)
  for _, node in ipairs(nodes) do
    local _, err = self:navigate(ctx, node.path)
    if err ~= nil then
      return nil, err
    end
  end
end

function M.action_tab_open(self, nodes)
  for _, node in ipairs(nodes) do
    local _, err = self:open({path = node.path, layout = "tab"})
    if err ~= nil then
      return nil, err
    end
  end
end

function M.action_vsplit_open(self, nodes)
  for _, node in ipairs(nodes) do
    local _, err = self:open({path = node.path, layout = "vertical"})
    if err ~= nil then
      return nil, err
    end
  end
end

M.action_child = M.action_open

M.is_parent = true

local file_kind = require("kivi.kind.file")
return setmetatable(M, {
  __index = function(_, k)
    return rawget(M, k) or file_kind[k]
  end,
})
