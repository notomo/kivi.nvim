local nodes = require("kivi/core/node")

local M = {}

local CollectResult = {}
CollectResult.__index = CollectResult

function CollectResult.get(self)
  if self._root ~= nil then
    return nodes.new(self._root), true
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

  local tbl = {}
  if root_or_job.is_job == nil then
    tbl._root = root_or_job
  else
    tbl._job = root_or_job
  end

  return setmetatable(tbl, CollectResult), nil
end

M.create = function(source)
  local tbl = {source = source}
  return setmetatable(tbl, Collector), nil
end

return M
