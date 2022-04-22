local Kind = require("kivi.core.kind")
local listlib = require("kivi.lib.list")

local Node = {}

function Node.new(raw_node, parent)
  vim.validate({ raw_node = { raw_node, "table" }, parent = { parent, "table", true } })
  local tbl = { parent = parent, _node = raw_node }
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

function Node.kind(self)
  local kind, err = Kind.new(self.kind_name)
  if err ~= nil then
    return nil, err
  end
  return kind, nil
end

local FlatNode = {}
FlatNode.__index = FlatNode

function FlatNode.new(node, index, depth)
  vim.validate({ node = { node, "table" }, index = { index, "number" }, depth = { depth, "number" } })
  local tbl = { _node = node, index = index, depth = depth }
  return setmetatable(tbl, FlatNode)
end

function FlatNode.__index(self, k)
  return rawget(FlatNode, k) or self._node[k]
end

local Nodes = {}
Nodes.__index = Nodes

function Nodes.new(raw_nodes, selected)
  vim.validate({ raw_nodes = { raw_nodes, "table" }, selected = { selected, "table", true } })
  local tbl = { _nodes = raw_nodes, _selected = selected or {} }
  if raw_nodes[1] then
    tbl.root_path = raw_nodes[1].path:get()
  end
  return setmetatable(tbl, Nodes)
end

function Nodes.from_node(root)
  vim.validate({ root = { root, "table" } })
  local raw_nodes = {}
  local index = 1
  Node.new(root):walk(function(node, depth)
    table.insert(raw_nodes, FlatNode.new(node, index, depth))
    index = index + 1
  end)
  return Nodes.new(raw_nodes)
end

function Nodes.from_selected(selected_nodes)
  local selected = {}
  for _, node in ipairs(selected_nodes) do
    selected[node.path] = node
  end
  return Nodes.new(selected_nodes, selected)
end

function Nodes.clear_selections(self)
  return Nodes.new(self._nodes, {})
end

function Nodes.toggle_selections(self, nodes)
  local selected = {}
  for k, v in pairs(self._selected) do
    selected[k] = v
  end

  for _, node in ipairs(nodes) do
    if selected[node.path] then
      selected[node.path] = nil
    else
      selected[node.path] = node
    end
  end
  return Nodes.new(self._nodes, selected)
end

function Nodes.is_selected(self, path)
  return self._selected[path] ~= nil
end

function Nodes.has_selections(self)
  return not vim.tbl_isempty(self._selected)
end

function Nodes.selected(self)
  local nodes = vim.tbl_values(self._selected)
  table.sort(nodes, function(a, b)
    return a.index < b.index
  end)
  return nodes
end

function Nodes.map(self, f)
  vim.validate({ f = { f, "function" } })
  return vim.tbl_map(f, self._nodes)
end

function Nodes.range(self, s, e)
  vim.validate({ s = { s, "number" }, e = { e, "number" } })
  local nodes = {}
  for i = s, e, 1 do
    table.insert(nodes, self._nodes[i])
  end
  return nodes
end

function Nodes.find(self, path)
  vim.validate({ path = { path, "string" } })
  for _, node in ipairs(self._nodes) do
    if node.path:get() == path then
      return node
    end
  end
  return nil
end

function Nodes.__index(self, k)
  if type(k) == "number" then
    return self._nodes[k]
  end
  return Nodes[k]
end

function Nodes.kind(self)
  local node = self._nodes[1]
  return node:kind()
end

function Nodes.group_by_kind(self)
  local cache = {}
  local kinds = {}
  for _, node in ipairs(self._nodes) do
    if not cache[node.kind_name] then
      local kind, err = node:kind()
      if err ~= nil then
        return nil, err
      end
      cache[node.kind_name] = kind
    end
    kinds[node.path] = cache[node.kind_name]
  end

  local node_groups = listlib.group_by(self._nodes, function(node)
    return kinds[node.path]
  end)

  local index = 0
  return function()
    index = index + 1
    local value = node_groups[index]
    if not value then
      return nil
    end
    return unpack(value)
  end
end

return Nodes
