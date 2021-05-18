local Node = require("kivi.core.node").Node

local M = {}

local CollectResult = {}
CollectResult.__index = CollectResult

function CollectResult.new(root)
  local tbl = {root = Node.new(root)}
  return setmetatable(tbl, CollectResult)
end

local Collector = {}
Collector.__index = Collector
M.Collector = Collector

function Collector.new(source)
  vim.validate({source = {source, "table"}})
  local tbl = {_source = source}
  return setmetatable(tbl, Collector)
end

function Collector.start(self, opts, callback)
  vim.validate({opts = {opts, "table"}, callback = {callback, "function"}})
  local raw_result, err = self._source:start(opts)
  if err ~= nil then
    return nil, err
  end
  local result = CollectResult.new(raw_result)

  callback(result.root)
  self._source:hook(result.root.path)

  return result, nil
end

return M
