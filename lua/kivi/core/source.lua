local modulelib = require("kivi.vendor.misclib.module")
local base = require("kivi.handler.source.base")

local Source = {}

function Source.new(source_name, source_opts)
  vim.validate({ source_name = { source_name, "string" }, source_opts = { source_opts, "table", true } })
  source_opts = source_opts or {}

  local source = modulelib.find("kivi.handler.source." .. source_name)
  if source == nil then
    return nil, "not found source: " .. source_name
  end

  local tbl = {
    name = source_name,
    opts = vim.tbl_extend("force", source.opts, source_opts),
    _source = source,
  }
  return setmetatable(tbl, Source), nil
end

function Source.__index(self, k)
  return rawget(Source, k) or self._source[k] or base[k]
end

function Source.start(self, opts, setup_opts)
  vim.validate({ opts = { opts, "table" }, setup_opts = { setup_opts, "table", true } })
  if setup_opts then
    local new_opts = self._source.setup(opts, vim.tbl_extend("force", self._source.setup_opts, setup_opts))
    return self._source.collect(new_opts)
  end
  return self._source.collect(opts)
end

return Source
