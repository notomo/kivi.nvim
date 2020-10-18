local modulelib = require("kivi/lib/module")
local filelib = require("kivi/lib/file")
local custom = require("kivi/custom")
local base = require("kivi/kind/base")
local vim = vim

local M = {}

local Action = function(kind, fn, action_opts, behavior)
  local tbl = {action_opts = action_opts, behavior = behavior}
  local action = setmetatable(tbl, kind)
  action.execute = function(self, items, ctx)
    return fn(self, items, ctx)
  end
  return action
end

local action_prefix = "action_"

local find_action = function(kind, action_name, action_opts)
  local name = action_name
  if name == "default" then
    name = kind.default_action
  end

  local key = action_prefix .. name
  local opts = vim.tbl_extend("force", kind.opts[name] or {}, action_opts)
  local behavior = vim.tbl_deep_extend("force", {quit = false}, kind.behaviors[name] or {})

  local action = kind[key]
  if action ~= nil then
    return Action(kind, action, opts, behavior), nil
  end

  return nil, "not found action: " .. name
end

local open_path = function(kind, source_name, opts)
  local source_opts = {}
  return kind._notifier:send("open_path", source_name, source_opts, opts)
end

M.create = function(executor, kind_name)
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

  local source_name = executor.source_name

  local kind = {}
  kind.name = kind_name
  kind.source_name = source_name
  kind.filelib = filelib
  kind.executor = executor
  kind.find_action = find_action
  kind.open_path = open_path
  kind._notifier = executor.notifier
  kind.__index = kind

  local source_user_opts = {}
  local source_user_behaviors = {}
  if custom.source_actions ~= nil and custom.source_actions[source_name] ~= nil then
    source_user_opts = custom.source_actions[source_name].opts or {}
    source_user_behaviors = custom.source_actions[source_name].behaviors or {}
  end
  local user_opts = {}
  local user_behaviors = {}
  if custom.kind_actions ~= nil and custom.kind_actions[kind_name] ~= nil then
    user_opts = custom.kind_actions[kind_name].opts or {}
    user_behaviors = custom.kind_actions[kind_name].behaviors or {}
  end
  kind.opts = vim.tbl_deep_extend("force", base.opts, origin.opts or {}, user_opts, source_user_opts)
  kind.behaviors = vim.tbl_deep_extend("force", base.behaviors, origin.behaviors or {}, user_behaviors, source_user_behaviors)

  return setmetatable(kind, origin), nil
end

return M
