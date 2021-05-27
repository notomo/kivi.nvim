local Source = require("kivi.core.source").Source
local Context = require("kivi.core.context").Context
local Loader = require("kivi.core.loader").Loader
local Executor = require("kivi.core.executor").Executor
local Options = require("kivi.core.option").Options
local View = require("kivi.view").View
local Renamer = require("kivi.view.renamer").Renamer
local Creator = require("kivi.view.creator").Creator

local M = {}

local Controller = {}
Controller.__index = Controller
M.Controller = Controller

function Controller.new()
  local tbl = {}
  return setmetatable(tbl, Controller)
end

function Controller.open(_, raw_opts)
  local opts, open_opts = Options.new(raw_opts)
  local source, err = Source.new(opts.source, raw_opts.source_opts)
  if err ~= nil then
    return nil, err
  end

  local ui, key = View.open(source, open_opts)
  local ctx = Context.new(source, ui, key, opts)
  return Loader.new(ctx.ui.bufnr):open(ctx, raw_opts.source_setup_opts)
end

function Controller.navigate(_, ctx, path, source_setup_opts)
  return Loader.new(ctx.ui.bufnr):navigate(ctx, path, source_setup_opts)
end

function Controller.navigate_parent(_, ctx, path)
  return Loader.new(ctx.ui.bufnr):navigate_parent(ctx, path)
end

function Controller.back(_, ctx, path)
  return Loader.new(ctx.ui.bufnr):back(ctx, path)
end

function Controller.expand_child(_, ctx, expanded)
  return Loader.new(ctx.ui.bufnr):expand_child(ctx, expanded)
end

function Controller.expand_parent(_, ctx, path, cursor_line_path, expanded)
  return Loader.new(ctx.ui.bufnr):expand_parent(ctx, path, cursor_line_path, expanded)
end

function Controller.reload(_, ctx)
  return Loader.new(ctx.ui.bufnr):reload()
end

function Controller.execute(_, action_name, range, opts, action_opts)
  local ctx, err = Context.get()
  if err ~= nil then
    return nil, err
  end

  local nodes = ctx.ui:selected_nodes(action_name, range)
  ctx.ui:reset_selections(action_name)
  return Executor.new(ctx.ui):execute(ctx, nodes, action_name, opts, action_opts)
end

function Controller.open_renamer(_, base_node, rename_items, has_cut)
  local ctx, err = Context.get()
  if err ~= nil then
    return nil, err
  end

  local kind, kind_err = base_node:kind()
  if err ~= nil then
    return nil, kind_err
  end

  local loader = Loader.new(ctx.ui.bufnr)
  Renamer.open(kind, loader, base_node, rename_items, has_cut)
end

function Controller.open_creator(_, base_node)
  local ctx, err = Context.get()
  if err ~= nil then
    return nil, err
  end

  local kind, kind_err = base_node:kind()
  if err ~= nil then
    return nil, kind_err
  end

  local loader = Loader.new(ctx.ui.bufnr)
  Creator.open(kind, loader, base_node)
end

return M
