local modulelib = require("kivi.vendor.misclib.module")
local Action = require("kivi.core.action")
local base = require("kivi.handler.kind.base")
local vim = vim

local Kind = {}

function Kind.new(name)
  vim.validate({ name = { name, "string" } })

  local kind = modulelib.find("kivi.handler.kind." .. name)
  if not kind then
    return nil, "not found kind: " .. name
  end

  local tbl = {
    name = name,
    opts = vim.tbl_deep_extend("force", base.opts, kind.opts or {}),
    _kind = kind,
  }
  return setmetatable(tbl, Kind), nil
end

function Kind.__index(self, k)
  return rawget(Kind, k) or self._kind[k] or base[k]
end

function Kind.find_action(self, action_name, action_opts)
  return Action.new(self, action_name, action_opts)
end

return Kind
