local Node = require("kivi.core.node").Node

local M = {}

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
M.Collector = Collector

function Collector.new(source)
  local tbl = {_source = source}
  return setmetatable(tbl, Collector)
end

function Collector.start(self, opts)
  local root_or_job, err = self._source:collect(opts)
  if err ~= nil then
    return nil, err
  end

  local tbl = {}
  if root_or_job.is_job == nil then
    tbl._root = root_or_job
  else
    tbl._job = root_or_job
  end

  return setmetatable(tbl, CollectResult), nil
end

return M
