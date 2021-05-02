local modulelib = require("kivi.lib.module")
local pathlib = require("kivi.lib.path")
local filelib = require("kivi.lib.file")
local HighlighterFactory = require("kivi.lib.highlight").HighlighterFactory
local base = require("kivi.source.base")

local M = {}

local Source = {}
M.Source = Source

function Source.new(source_name, source_opts, setup_opts)
  vim.validate({
    source_name = {source_name, "string"},
    source_opts = {source_opts, "table", true},
    setup_opts = {setup_opts, "table", true},
  })
  source_opts = source_opts or {}
  setup_opts = setup_opts or {}

  local source = modulelib.find("kivi.source." .. source_name)
  if source == nil then
    return nil, "not found source: " .. source_name
  end

  local tbl = {
    name = source_name,
    bufnr = vim.api.nvim_get_current_buf(),
    filetype = ("kivi-%s"):format(source_name),
    highlights = HighlighterFactory.new("kivi-highlight"),
    pathlib = pathlib,
    filelib = filelib,
    opts = vim.tbl_extend("force", source.opts, source_opts),
    setup_opts = vim.tbl_extend("force", source.setup_opts, setup_opts),
    _source = source,
  }
  return setmetatable(tbl, Source), nil
end

function Source.__index(self, k)
  return rawget(Source, k) or self._source[k] or base[k]
end

function Source.start(self, opts)
  local new_opts = self:setup(opts)
  return self:collect(new_opts)
end

return M
