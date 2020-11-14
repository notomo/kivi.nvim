local modulelib = require("kivi/lib/module")
local pathlib = require("kivi/lib/path")
local filelib = require("kivi/lib/file")
local highlights = require("kivi/lib/highlight")
local base = require("kivi/source/base")

local M = {}

local Source = {}
Source.__index = Source
M.Source = Source

function Source.new(source_name, _)
  vim.validate({source_name = {source_name, "string", true}})
  source_name = source_name or "file"

  local origin
  if source_name == "base" then
    origin = base
  else
    local found = modulelib.find_source(source_name)
    if found == nil then
      return nil, "not found source: " .. source_name
    end
    origin = setmetatable(found, base)
    origin.__index = origin
  end

  local tbl = {
    name = source_name,
    bufnr = vim.api.nvim_get_current_buf(),
    filetype = ("kivi-%s"):format(source_name),
    highlights = highlights.new_factory("kivi-highlight"),
    pathlib = pathlib,
    filelib = filelib,
  }
  return setmetatable(tbl, origin), nil
end

return M
