local Path = require("kivi.lib.path").Path
local tbllib = require("kivi.lib.table")

local default_opts = {
  source = "file",
  path = ".",
  expanded = {},
}

local default_open_opts = {
  layout = { type = "no" },
}

local Options = {}
Options.__index = Options

function Options.new(raw_opts)
  raw_opts = raw_opts or {}

  local opts = tbllib.extend(default_opts, raw_opts)
  opts.path = Path.new(opts.path)

  local open_opts = tbllib.extend(default_open_opts, raw_opts)

  return setmetatable(opts, Options), open_opts
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

return Options
