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

function Node.root(self)
  local current = self
  while true do
    if current.parent == nil then
      return current
    end
    current = current.parent
  end
end

function Node.parent_or_root(self)
  if self.parent == nil then
    return self:root()
  end
  return self.parent
end

function Node.move_to(self, parent)
  local old = vim.deepcopy(self)
  old.path = parent.path:join(self.path:head())
  old.parent = nil
  old.__index = nil
  return Node.new(old, parent)
end

function Node.walk(self, f)
  return self:_walk(0, f)
end

function Node._walk(self, depth, f)
  f(self, depth)
  for _, child in ipairs(self.children or {}) do
    Node.new(child, self):_walk(depth + 1, f)
  end
end

return M
