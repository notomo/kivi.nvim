local M = {}

local Node = {}
Node.__index = Node

function Node.all(self)
  local nodes = {self}
  for _, child in ipairs(self.children or {}) do
    local node = M.new(child, self)
    vim.list_extend(nodes, node:all())
  end
  return nodes
end

function Node.root(self)
  local current = self
  while true do
    if current.parent == nil then
      return current
    end
    current = current.parent
  end
end

M.new = function(raw, parent)
  local tbl = {parent = parent}
  tbl.__index = tbl
  local meta = setmetatable(tbl, Node)
  return setmetatable(raw, meta)
end

return M
