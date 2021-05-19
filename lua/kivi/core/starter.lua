local Source = require("kivi.core.source").Source
local Context = require("kivi.core.context").Context
local Loader = require("kivi.core.loader").Loader
local Executor = require("kivi.core.executor").Executor
local Kind = require("kivi.core.kind").Kind
local Options = require("kivi.core.option").Options
local View = require("kivi.view").View
local Renamer = require("kivi.view.renamer").Renamer
local Creator = require("kivi.view.creator").Creator

local M = {}

local Starter = {}
Starter.__index = Starter
M.Starter = Starter

function Starter.new()
  local tbl = {}
  return setmetatable(tbl, Starter)
end

function Starter.open(_, raw_opts)
  local old_ctx = Context.get()
  if old_ctx and not raw_opts.source then
    raw_opts.source = old_ctx.source.name
  end

  local opts, open_opts = Options.new(raw_opts)

  local source, err = Source.new(opts.source, raw_opts.source_opts)
  if err ~= nil then
    return nil, err
  end

  local ui, key = View.open(source, open_opts)
  local ctx = Context.new(source, ui, key, opts)
  return Loader.new(ctx.ui.bufnr):open(ctx, raw_opts.source_setup_opts)
end

function Starter.navigate(_, ctx, path, setup_opts)
  return Loader.new(ctx.ui.bufnr):navigate(ctx, path, setup_opts)
end

function Starter.back(_, ctx, path)
  return Loader.new(ctx.ui.bufnr):back(ctx, path)
end

function Starter.expand(_, ctx, expanded)
  return Loader.new(ctx.ui.bufnr):expand(ctx, expanded)
end

function Starter.execute(self, action_name, range, opts, action_opts)
  local ctx, err = Context.get()
  if err ~= nil then
    return nil, err
  end

  local nodes = ctx.ui:selected_nodes(action_name, range)
  ctx.ui:reset_selections(action_name)
  return Executor.new(self, ctx.ui, ctx.source):execute(ctx, nodes, action_name, opts, action_opts)
end

function Starter.rename(self, base_node, rename_items, has_cut)
  local ctx, err = Context.get()
  if err ~= nil then
    return nil, err
  end

  local kind, kind_err = Kind.new(self, ctx.source.kind_name)
  if err ~= nil then
    return nil, kind_err
  end

  local loader = Loader.new(ctx.ui.bufnr)
  Renamer.open(kind, loader, base_node, rename_items, has_cut)
end

function Starter.create(self, base_node)
  local ctx, err = Context.get()
  if err ~= nil then
    return nil, err
  end

  local kind, kind_err = Kind.new(self, ctx.source.kind_name)
  if err ~= nil then
    return nil, kind_err
  end

  local loader = Loader.new(ctx.ui.bufnr)
  Creator.open(kind, loader, base_node)
end

return M
