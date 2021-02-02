local M = {}

M.action_open = function(self, nodes)
  for _, node in ipairs(nodes) do
    local _, err = self:start_path({path = node.path})
    if err ~= nil then
      return nil, err
    end
  end
end

M.action_tab_open = function(self, nodes)
  for _, node in ipairs(nodes) do
    local _, err = self:start_path({path = node.path, layout = "tab", new = true})
    if err ~= nil then
      return nil, err
    end
  end
end

M.action_vsplit_open = function(self, nodes)
  for _, node in ipairs(nodes) do
    local _, err = self:start_path({path = node.path, layout = "vertical", new = true})
    if err ~= nil then
      return nil, err
    end
  end
end

M.action_child = M.action_open

M.is_parent = true

return setmetatable(M, require("kivi/kind/file"))
