local M = {}

local Node = {}
M.Node = Node

function Node.new(raw_node, parent)
  vim.validate({raw_node = {raw_node, "table"}, parent = {parent, "table", true}})
  local tbl = {parent = parent, _node = raw_node}
  return setmetatable(tbl, Node)
end

function Node.__index(self, k)
  return rawget(Node, k) or self._node[k]
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
  local old = vim.deepcopy(self._node)
  old.path = parent.path:join(self.path:head())
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
