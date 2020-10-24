local M = {}

M.action_open = function(self, nodes)
  for _, node in ipairs(nodes) do
    self:open_path("file", {path = node.path, layout = "no"})
  end
end

M.action_tab_open = function(self, nodes)
  for _, node in ipairs(nodes) do
    self:open_path("file", {path = node.path, layout = "tab"})
  end
end

M.action_child = M.action_open

M.parent_kind_name = "file"

return M