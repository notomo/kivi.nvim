local custom = require("kivi.custom")
local Path = require("kivi.lib.path").Path
local Target = require("kivi.core.target").Target

local M = {}

local default_opts = {
  path = ".",
  layout = "no",
  back = false,
  expanded = {},
  expand = false,
  new = false,
  target = "current",
}

local Options = {}
Options.__index = Options
M.Options = Options

function Options.new(raw_opts)
  local opts = vim.tbl_extend("force", default_opts, custom.opts, raw_opts or {})
  opts.path = Path.new(Target.new(opts.target):path() or opts.path)
  return setmetatable(opts, Options)
end

function Options.merge(self, opts)
  local raw_opts = {}
  for key in pairs(default_opts) do
    raw_opts[key] = self[key]
  end
  for key, value in pairs(opts) do
    raw_opts[key] = value
  end
  raw_opts.expanded = vim.tbl_deep_extend("force", self.expanded, opts.expanded or {})
  return Options.new(raw_opts)
end

return M
