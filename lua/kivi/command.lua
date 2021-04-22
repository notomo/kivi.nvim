local repository = require("kivi.core.repository")
local Kind = require("kivi.core.kind").Kind
local Loader = require("kivi.core.loader").Loader
local Starter = require("kivi.core.starter").Starter
local Renamer = require("kivi.view.renamer").Renamer
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

function Command.open(source_name, opts)
  vim.validate({source_name = {source_name, "string"}, opts = {opts, "table", true}})
  opts = opts or {}
  return Starter.new():open(source_name, opts)
end

function Command.execute(action_name, opts, action_opts)
  vim.validate({
    action_name = {action_name, "string"},
    opts = {opts, "table", true},
    action_opts = {action_opts, "table", true},
  })
  opts = opts or {}
  action_opts = action_opts or {}
  local range = modelib.visual_range() or {first = vim.fn.line("."), last = vim.fn.line(".")}
  return Starter.new():execute(action_name, range, opts, action_opts)
end

function Command.read(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end

  local path = vim.api.nvim_buf_get_name(bufnr)
  if path:match("/kivi$") then
    return Loader.new(bufnr):load()
  elseif path:match("/kivi%-renamer$") then
    return Renamer.load(bufnr)
  end
end

function Command.is_parent()
  local ctx, err = repository.get_from_path()
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
