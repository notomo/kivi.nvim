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

function Source.start(self, opts, callback, source_setup_opts)
  return self:_start(opts, source_setup_opts):next(function(raw_result, err)
    if err then
      return err
    end
    local nodes = require("kivi.core.nodes").from_node(raw_result)
    local bufnr = callback(nodes)
    ---@diagnostic disable-next-line: invisible
    self._source.hook(nodes.root_path, bufnr)
  end)
end

--- @param opts table
--- @param setup_opts table?
function Source._start(self, opts, setup_opts)
  if setup_opts then
    local new_opts = self._source.setup(opts, vim.tbl_extend("force", self._source.setup_opts, setup_opts))
    return self._source.collect(new_opts)
  end
  return self._source.collect(opts)
end

return Source
