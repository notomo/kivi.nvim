local Context = require("kivi.core.context").Context
local Kind = require("kivi.core.kind").Kind
local Starter = require("kivi.core.starter").Starter
local custom = require("kivi.core.custom")
local Router = require("kivi.view.router").Router
local messagelib = require("kivi.lib.message")
local modelib = require("kivi.lib.mode")

local M = {}

local Command = {}
Command.__index = Command
M.Command = Command

function Command.new(name, ...)
  local args = {...}
  local f = function()
    return Command[name](unpack(args))
  end

  local ok, result, msg = xpcall(f, debug.traceback)
  if not ok then
    return messagelib.error(result)
  elseif msg then
    return messagelib.warn(msg)
  end
  return result
end

function Command.open(raw_opts)
  vim.validate({raw_opts = {raw_opts, "table", true}})
  raw_opts = raw_opts or {}
  return Starter.new():open(raw_opts)
end

function Command.execute(action_name, opts, action_opts)
  vim.validate({
    action_name = {action_name, "string"},
    opts = {opts, "table", true},
    action_opts = {action_opts, "table", true},
  })
  local range = modelib.current_row_range()
  opts = opts or {}
  action_opts = action_opts or {}
  return Starter.new():execute(action_name, range, opts, action_opts)
end

function Command.setup(config)
  vim.validate({config = {config, "table"}})
  custom.set(config)
end

function Command.read(bufnr)
  return Router.read(bufnr)
end

function Command.write(bufnr)
  return Router.write(bufnr)
end

function Command.delete(bufnr)
  return Router.delete(bufnr)
end

function Command.is_parent()
  local ctx, err = Context.get()
  if err ~= nil then
    return false
  end

  local nodes = ctx.ui:selected_nodes()
  local node = nodes[1]
  local kind_name = node.kind_name or ctx.source.kind_name
  local kind, kind_err = Kind.new(Starter.new(), kind_name)
  if kind_err ~= nil then
    return false, kind_err
  end

  return kind.is_parent == true, nil
end

return M