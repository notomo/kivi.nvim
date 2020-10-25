local modulelib = require("kivi/lib/module")
local filelib = require("kivi/lib/file")
local pathlib = require("kivi/lib/path")
local inputlib = require("kivi/lib/input")
local base = require("kivi/kind/base")
local vim = vim

local M = {}

local Action = function(kind, fn, action_opts, behavior)
  local tbl = {action_opts = action_opts, behavior = behavior}
  kind.__index = kind
  local action = setmetatable(tbl, kind)
  action.execute = function(self, nodes, ctx)
    return fn(self, nodes, ctx)
  end
  return action
end

local action_prefix = "action_"

local Kind = {}

function Kind.find_action(self, action_name, action_opts)
  local key = action_prefix .. action_name
  local opts = vim.tbl_extend("force", self.opts[action_name] or {}, action_opts)
  local behavior = vim.tbl_deep_extend("force", {quit = false}, self.behaviors[action_name] or {})

  local action = self[key]
  if action ~= nil then
    return Action(self, action, opts, behavior), nil
  end

  return nil, "not found action: " .. action_name
end

function Kind.start_path(self, opts, source_name)
  opts = opts or {}
  source_name = source_name or self.source_name
  local source_opts = {}
  return self._notifier:send("start_path", source_name, source_opts, opts)
end

function Kind.confirm(self, message, nodes)
  local paths = vim.tbl_map(function(node)
    return node.path
  end, nodes)
  local target = table.concat(paths, "\n")
  local msg = ("%s\n%s"):format(target, message)
  return self._input_reader:confirm(msg)
end

M.create = function(executor, kind_name, action_name)
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
    source_name = executor.source_name,
    filelib = filelib,
    pathlib = pathlib,
    executor = executor,
    opts = vim.tbl_deep_extend("force", base.opts, origin.opts or {}),
    behaviors = vim.tbl_deep_extend("force", base.behaviors, origin.behaviors or {}),
    _notifier = executor.notifier,
    _input_reader = inputlib.reader(),
  }
  tbl = vim.tbl_extend("error", tbl, Kind)
  local self = setmetatable(tbl, origin)

  if kind_name ~= self.parent_kind_name and self.parent_kind_name ~= nil and self[action_prefix .. action_name] == nil then
    return M.create(executor, self.parent_kind_name, action_name)
  end

  return self, nil
end

return M
