local Context = require("kivi.core.context")
local Loader = require("kivi.core.loader")

local Controller = {}
Controller.__index = Controller

function Controller.new()
  local tbl = {}
  return setmetatable(tbl, Controller)
end

function Controller.open(_, raw_opts)
  local opts, open_opts = require("kivi.core.option").new(raw_opts)
  local source, err = require("kivi.core.source").new(opts.source, opts.source_opts)
  if err ~= nil then
    return nil, err
  end

  local ui, key = require("kivi.view").open(source, open_opts)
  local ctx = Context.new(source, ui, key, opts)
  return Loader.new(ctx.ui.bufnr):open(ctx, opts.source_setup_opts)
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

function Controller.shrink(_, ctx, path, cursor_line_path)
  return Loader.new(ctx.ui.bufnr):shrink(ctx, path, cursor_line_path)
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
  return require("kivi.core.executor").new(ctx.ui):execute(ctx, nodes, action_name, opts, action_opts)
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
  require("kivi.view.renamer").open(kind, loader, base_node, rename_items, has_cut)
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
  require("kivi.view.creator").open(kind, loader, base_node)
end

return Controller
