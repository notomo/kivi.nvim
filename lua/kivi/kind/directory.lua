local M = {}

M.action_open = function(self, nodes)
  for _, node in ipairs(nodes) do
    self:start_path({path = node.path})
  end
end

M.action_tab_open = function(self, nodes)
  for _, node in ipairs(nodes) do
    self:start_path({path = node.path, layout = "tab"})
  end
end

M.action_child = M.action_open

return setmetatable(M, require("kivi/kind/file"))
