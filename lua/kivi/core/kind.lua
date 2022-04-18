local modulelib = require("kivi.vendor.misclib.module")
local filelib = require("kivi.lib.file")
local pathlib = require("kivi.lib.path")
local inputlib = require("kivi.lib.input")
local messagelib = require("kivi.lib.message")
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
    filelib = filelib,
    pathlib = pathlib,
    messagelib = messagelib,
    opts = vim.tbl_deep_extend("force", base.opts, kind.opts or {}),
    input_reader = inputlib.reader(),
    controller = require("kivi.controller").new(),
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

function Kind.confirm(self, message, nodes)
  local paths = vim.tbl_map(function(node)
    return node.path:get()
  end, nodes)
  local target = table.concat(paths, "\n")
  local msg = ("%s\n%s"):format(target, message)
  return self.input_reader:confirm(msg)
end

return Kind
