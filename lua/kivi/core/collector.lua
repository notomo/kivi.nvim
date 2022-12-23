local Nodes = require("kivi.core.nodes")

local M = {}

function M.start(source, opts, callback, source_setup_opts)
  vim.validate({
    source = { source, "table" },
    opts = { opts, "table" },
    callback = { callback, "function" },
    source_setup_opts = { source_setup_opts, "table", true },
  })
  return source:start(opts, source_setup_opts):next(function(raw_result)
    local nodes = Nodes.from_node(raw_result)
    local bufnr = callback(nodes)
    source.hook(nodes.root_path, bufnr)
  end)
end

return M
