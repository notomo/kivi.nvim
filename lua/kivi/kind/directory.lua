local M = {}

M.action_open = function(self, items)
  for _, item in ipairs(items) do
    self:open_path("file", {path = item.path, layout = "no"})
  end
end

M.action_tab_open = function(self, items)
  for _, item in ipairs(items) do
    self:open_path("file", {path = item.path, layout = "tab"})
  end
end

M.action_child = function(self, items)
  return self:action_open(items)
end

M.action_parent = function(self, items)
  return self:action_open(items)
end

M.default_action = "open"

return M
