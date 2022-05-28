local Nodes = require("kivi.core.nodes")

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
  return self._source:start(opts, source_setup_opts):next(function(raw_result)
    local nodes = Nodes.from_node(raw_result)
    local bufnr = callback(nodes)
    self._source:hook(nodes.root_path, bufnr)
  end)
end

return Collector
