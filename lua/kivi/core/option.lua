local custom = require("kivi/custom")
local Path = require("kivi/lib/path").Path

local M = {}

local default_opts = {path = ".", layout = "no", back = false}

local Options = {}
Options.__index = Options
M.Options = Options

function Options.new(raw_opts)
  local opts = vim.tbl_extend("force", default_opts, custom.opts, raw_opts or {})
  opts.path = Path.new(opts.path)
  return setmetatable(opts, Options)
end

return M
