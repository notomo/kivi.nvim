local Nodes = require("kivi.core.node")

local CollectResult = {}
CollectResult.__index = CollectResult

function CollectResult.new(root)
  local tbl = { nodes = Nodes.from_node(root) }
  return setmetatable(tbl, CollectResult)
end

local Collector = {}
Collector.__index = Collector

function Collector.new(source)
  vim.validate({ source = { source, "table" } })
  local tbl = { _source = source }
  return setmetatable(tbl, Collector)
end

function Collector.start(self, opts, callback, source_setup_opts)
  vim.validate({
    opts = { opts, "table" },
    callback = { callback, "function" },
    source_setup_opts = { source_setup_opts, "table", true },
  })
  local raw_result, err = self._source:start(opts, source_setup_opts)
  if err ~= nil then
    return nil, err
  end
  local result = CollectResult.new(raw_result)

  callback(result.nodes)
  self._source:hook(result.nodes.root_path)

  return result, nil
end

return Collector
