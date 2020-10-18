local source_core = require("kivi/core/source")

local M = {}

local CollectResult = {}
CollectResult.__index = CollectResult

function CollectResult.get(self)
  if self._items ~= nil then
    return self._items, true
  end
  return {}, false
end

local Collector = {}
Collector.__index = Collector

function Collector.start(self, opts)
  local items_or_job, err = self.source:collect(opts)
  if err ~= nil then
    return nil, err
  end

  local tbl = {source = self.source}
  if vim.tbl_islist(items_or_job) then
    tbl._items = items_or_job
  else
    tbl._job = items_or_job
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
