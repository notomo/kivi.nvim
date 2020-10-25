local M = {}
M.__index = M

local adjust_window = function()
  vim.api.nvim_command("wincmd w")
end

M.action_open = function(self, nodes)
  adjust_window()
  for _, node in ipairs(nodes) do
    self.filelib.open(node.path)
  end
end

M.action_tab_open = function(self, nodes)
  for _, node in ipairs(nodes) do
    self.filelib.tab_open(node.path)
  end
end

M.action_vsplit_open = function(self, nodes)
  adjust_window()
  for _, node in ipairs(nodes) do
    self.filelib.vsplit_open(node.path)
  end
end

M.action_child = M.action_open

M.action_parent = function(self, nodes)
  local node = nodes[1]
  if node == nil then
    return
  end
  local root = node:root()
  self:start_path({path = self.pathlib.add_trailing_slash(vim.fn.fnamemodify(root.path, ":h:h"))})
end

M.action_delete = function(self, nodes)
  local yes = self:confirm("delete?", nodes)
  if not yes then
    return
  end

  for _, node in ipairs(nodes) do
    self.filelib.delete(node.path)
  end
  self:start_path()
end

return M
