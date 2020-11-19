local modulelib = require("kivi/lib/module")
local filelib = require("kivi/lib/file")
local pathlib = require("kivi/lib/path")
local inputlib = require("kivi/lib/input")
local messagelib = require("kivi/lib/message")
local Action = require("kivi/core/action").Action
local vim = vim

local M = {}

local Kind = {}
Kind.__index = Kind
M.Kind = Kind
local base = setmetatable(require("kivi/kind/base"), Kind)

function Kind.new(starter, kind_name)
  vim.validate({kind_name = {kind_name, "string"}})

  local origin
  if kind_name == "base" then
    origin = base
  else
    local found = modulelib.find_kind(kind_name)
    if found == nil then
      return nil, "not found kind: " .. kind_name
    end
    origin = modulelib.set_base(found, base)
    origin.__index = origin
  end

  local tbl = {
    name = kind_name,
    filelib = filelib,
    pathlib = pathlib,
    messagelib = messagelib,
    opts = vim.tbl_deep_extend("force", base.opts, origin.opts or {}),
    behaviors = vim.tbl_deep_extend("force", base.behaviors, origin.behaviors or {}),
    input_reader = inputlib.reader(),
    _starter = starter,
  }
  return setmetatable(tbl, origin), nil
end

local ACTION_PREFIX = "action_"
function Kind.find_action(self, action_name, action_opts)
  local key = ACTION_PREFIX .. action_name
  local opts = vim.tbl_extend("force", self.opts[action_name] or {}, action_opts)
  local behavior = vim.tbl_deep_extend("force", {quit = false}, self.behaviors[action_name] or {})

  local action = self[key]
  if action ~= nil then
    return Action.new(self, action, opts, behavior), nil
  end

  return nil, "not found action: " .. action_name
end

function Kind.start_path(self, opts, source_name)
  return self._starter:open(source_name, opts)
end

function Kind.start_renamer(self, base_node, rename_items, has_cut)
  return self._starter:rename(base_node, rename_items, has_cut)
end

function Kind.start_creator(self, base_node)
  return self._starter:create(base_node)
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
