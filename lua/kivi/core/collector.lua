local source_core = require("kivi/core/source")
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

  local tbl = {source = self.source}
  if root_or_job.is_job == nil then
    tbl._root = root_or_job
  else
    tbl._job = root_or_job
  end

  return setmetatable(tbl, CollectResult), nil
end

M.create = function(source_name, source_opts, source_bufnr)
  local source, err = source_core.create(source_name, source_opts, source_bufnr)
  if err ~= nil then
    return nil, err
  end

  local tbl = {source = source}
  return setmetatable(tbl, Collector), nil
end

return M
