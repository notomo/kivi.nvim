local M = {}

local Node = {}
Node.__index = Node
M.Node = Node

function Node.new(raw, parent)
  local tbl = {parent = parent}
  tbl.__index = tbl
  local meta = setmetatable(tbl, Node)
  return setmetatable(raw, meta)
end

function Node.all(self)
  local nodes = {self}
  for _, child in ipairs(self.children or {}) do
    local node = Node.new(child, self)
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

function Node.move_to(self, parent)
  local old = vim.deepcopy(self)
  old.path = parent.path:join(self.path:head())
  old.parent = nil
  old.__index = nil
  return Node.new(old, parent)
end

return M
