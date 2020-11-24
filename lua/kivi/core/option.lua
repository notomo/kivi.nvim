local custom = require("kivi/custom")
local Path = require("kivi/lib/path").Path
local Target = require("kivi/core/target").Target

local M = {}

local default_opts = {
  path = ".",
  layout = "no",
  back = false,
  expanded = {},
  expand = false,
  new = false,
  target = nil,
}

local Options = {}
Options.__index = Options
M.Options = Options

function Options.new(raw_opts)
  local opts = vim.tbl_extend("force", default_opts, custom.opts, raw_opts or {})
  opts.path = Path.new(Target.new(opts.target):path() or opts.path)
  return setmetatable(opts, Options)
end

function Options.clone(self, path)
  local opts = vim.deepcopy(self)
  opts.path = path
  return Options.new(opts)
end

return M
