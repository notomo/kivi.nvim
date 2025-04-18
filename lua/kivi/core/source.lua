local modulelib = require("kivi.vendor.misclib.module")
local base = require("kivi.handler.source.base")

--- @class KiviSource
--- @field name string
--- @field opts table
--- @field init_path fun(initial_bufnr:integer):string
--- @field private _source table
local Source = {}

--- @param source_name string
--- @param source_opts table?
--- @return KiviSource|string
function Source.new(source_name, source_opts)
  source_opts = source_opts or {}

  local source = modulelib.find("kivi.handler.source." .. source_name)
  if source == nil then
    return "not found source: " .. source_name
  end

  local tbl = {
    name = source_name,
    opts = vim.tbl_extend("force", source.opts, source_opts),
    _source = source,
  }
  return setmetatable(tbl, Source)
end

function Source.__index(self, k)
  return rawget(Source, k) or self._source[k] or base[k]
end

function Source.start(self, opts)
  return self._source.collect(opts):next(function(raw_result, err)
    if err then
      return require("kivi.vendor.promise").reject(err)
    end
    return require("kivi.core.nodes").from_node(raw_result)
  end)
end

--- @class KiviSourceHookContext
--- @field nodes KiviNodes
--- @field bufnr integer
--- @field reload boolean?

--- @param hook_ctx KiviSourceHookContext
function Source.hook(self, hook_ctx)
  self._source.hook(hook_ctx)
end

return Source
