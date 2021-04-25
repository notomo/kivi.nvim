local modulelib = require("kivi.lib.module")
local pathlib = require("kivi.lib.path")
local filelib = require("kivi.lib.file")
local highlights = require("kivi.lib.highlight")
local base = require("kivi.source.base")

local M = {}

local Source = {}
M.Source = Source

function Source.new(source_name, _)
  vim.validate({source_name = {source_name, "string"}})

  local source = modulelib.find("kivi.source." .. source_name)
  if source == nil then
    return nil, "not found source: " .. source_name
  end

  local tbl = {
    name = source_name,
    bufnr = vim.api.nvim_get_current_buf(),
    filetype = ("kivi-%s"):format(source_name),
    highlights = highlights.new_factory("kivi-highlight"),
    pathlib = pathlib,
    filelib = filelib,
    _source = source,
  }
  return setmetatable(tbl, Source), nil
end

function Source.__index(self, k)
  return rawget(Source, k) or self._source[k] or base[k]
end

return M
