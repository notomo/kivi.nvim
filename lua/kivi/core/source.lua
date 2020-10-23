local modulelib = require("kivi/lib/module")
local pathlib = require("kivi/lib/path")
local filelib = require("kivi/lib/file")
local highlights = require("kivi/lib/highlight")
local base = require("kivi/source/base")

local M = {}

M.create = function(source_name, _, source_bufnr)
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

  local source = {}
  source.name = source_name
  source.bufnr = source_bufnr
  source.highlights = highlights.new_factory("kivi-highlight")
  source.pathlib = pathlib
  source.filelib = filelib

  return setmetatable(source, origin), nil
end

return M
