local Kind = require("kivi.core.kind")
local listlib = require("kivi.vendor.misclib.collection.list")
local pathlib = require("kivi.lib.path")

--- @class KiviNode
--- @field parent KiviNode?
--- @field path string
--- @field kind_name string
--- @field children KiviNode[]
--- @field private _node table
local Node = {}

--- @param raw_node table
--- @param parent table?
function Node.new(raw_node, parent)
  local tbl = {
    parent = parent,
    _node = raw_node,
  }
  return setmetatable(tbl, Node)
end

function Node.__index(self, k)
  return rawget(Node, k) or self._node[k]
end

function Node.raw(self)
  local values = {}
  for k, v in pairs(self._node) do
    values[k] = v
  end
  values.parent = nil
  return values
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
  old.path = pathlib.join(parent.path, pathlib.tail(self.path))
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
  return Kind.new(self.kind_name)
end

--- @class KiviFlatNode
--- @field index integer
--- @field path string
--- @field kind_name string
--- @field kind fun(self:KiviFlatNode):KiviKind
--- @field parent_or_root fun(self:KiviFlatNode):KiviNode
--- @field private _node table
local FlatNode = {}
FlatNode.__index = FlatNode

--- @param node table
--- @param index integer
--- @param depth integer
function FlatNode.new(node, index, depth)
  local tbl = {
    _node = node,
    index = index,
    depth = depth,
  }
  return setmetatable(tbl, FlatNode)
end

function FlatNode.__index(self, k)
  return rawget(FlatNode, k) or self._node[k]
end

function FlatNode.raw(self)
  local values = {}
  for k, v in pairs(self._node:raw()) do
    values[k] = v
  end
  values.parent = nil
  return values
end

--- @class KiviNodes
--- @field _nodes KiviFlatNode[]
--- @field _selected table<string,KiviNode>
local Nodes = {}
Nodes.__index = Nodes

--- @param raw_nodes table
--- @param selected table?
function Nodes.new(raw_nodes, selected)
  local tbl = {
    _nodes = raw_nodes,
    _selected = selected or {},
  }
  if raw_nodes[1] then
    tbl.root_path = raw_nodes[1].path
  end
  return setmetatable(tbl, Nodes)
end

--- @param root table
function Nodes.from_node(root)
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

--- @param f function
function Nodes.map(self, f)
  return vim.iter(self._nodes):map(f):totable()
end

function Nodes.iter(self)
  return vim.iter(self._nodes)
end

--- @param s integer
--- @param e integer
function Nodes.range(self, s, e)
  local nodes = {}
  for i = s, e, 1 do
    table.insert(nodes, self._nodes[i])
  end
  return nodes
end

--- @param path string
function Nodes.find(self, path)
  for _, node in ipairs(self._nodes) do
    if node.path == path then
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
      local kind = node:kind()
      if type(kind) == "string" then
        local err = kind
        return err
      end
      cache[node.kind_name] = kind
    end
    kinds[node.path] = cache[node.kind_name]
  end

  local node_groups = listlib.group_by_adjacent(self._nodes, function(node)
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
