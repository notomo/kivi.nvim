local source_core = require("kivi/core/source")

local M = {}

local Node = {}
Node.__index = Node

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

local CollectResult = {}
CollectResult.__index = CollectResult

function CollectResult.get(self)
  if self._root ~= nil then
    return Node.new(self._root), true
  end
  return {}, false
end

local Collector = {}
Collector.__index = Collector

function Collector.start(self, opts)
  local root_or_job, err = self.source:collect(opts)
  if err ~= nil then
    return nil, err
  end

  local tbl = {source = self.source}
  if root_or_job.is_job == nil then
    tbl._root = root_or_job
  else
    tbl._job = root_or_job
  end

  return setmetatable(tbl, CollectResult), nil
end

M.create = function(source_name, source_opts)
  local source, err = source_core.create(source_name, source_opts)
  if err ~= nil then
    return nil, err
  end

  local tbl = {source = source}
  return setmetatable(tbl, Collector), nil
end

return M
