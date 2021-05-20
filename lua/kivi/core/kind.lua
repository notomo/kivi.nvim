local modulelib = require("kivi.lib.module")
local filelib = require("kivi.lib.file")
local pathlib = require("kivi.lib.path")
local inputlib = require("kivi.lib.input")
local messagelib = require("kivi.lib.message")
local Action = require("kivi.core.action").Action
local base = require("kivi.kind.base")
local vim = vim

local M = {}

local Kind = {}
M.Kind = Kind

function Kind.new(starter, kind_name)
  vim.validate({kind_name = {kind_name, "string"}})

  local kind = modulelib.find("kivi.kind." .. kind_name)
  if kind == nil then
    return nil, "not found kind: " .. kind_name
  end

  local tbl = {
    name = kind_name,
    filelib = filelib,
    pathlib = pathlib,
    messagelib = messagelib,
    opts = vim.tbl_deep_extend("force", base.opts, kind.opts or {}),
    behaviors = vim.tbl_deep_extend("force", base.behaviors, kind.behaviors or {}),
    input_reader = inputlib.reader(),
    _starter = starter,
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

function Kind.navigate(self, ...)
  return self._starter:navigate(...)
end

function Kind.open(self, ...)
  return self._starter:open(...)
end

function Kind.back(self, ...)
  return self._starter:back(...)
end

function Kind.expand(self, ...)
  return self._starter:expand(...)
end

function Kind.open_renamer(self, ...)
  return self._starter:open_renamer(...)
end

function Kind.open_creator(self, ...)
  return self._starter:open_creator(...)
end

function Kind.confirm(self, message, nodes)
  local paths = vim.tbl_map(function(node)
    return node.path:get()
  end, nodes)
  local target = table.concat(paths, "\n")
  local msg = ("%s\n%s"):format(target, message)
  return self.input_reader:confirm(msg)
end

return M
