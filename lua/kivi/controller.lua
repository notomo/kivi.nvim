local Context = require("kivi.core.context")
local Loader = require("kivi.core.loader")

local M = {}

function M.open(raw_opts)
  local opts, open_opts = require("kivi.core.option").new(raw_opts)
  local source, err = require("kivi.core.source").new(opts.source, opts.source_opts)
  if err ~= nil then
    return require("kivi.vendor.promise").reject(err)
  end

  local ui, key = require("kivi.view").open(source, open_opts)
  local ctx = Context.new(source, ui, key, opts)
  return Loader.new(ctx.ui.bufnr):open(ctx, opts.source_setup_opts)
end

function M.navigate(ctx, path, source_setup_opts)
  return Loader.new(ctx.ui.bufnr):navigate(ctx, path, source_setup_opts)
end

function M.navigate_parent(ctx, path)
  return Loader.new(ctx.ui.bufnr):navigate_parent(ctx, path)
end

function M.back(ctx, path)
  return Loader.new(ctx.ui.bufnr):back(ctx, path)
end

function M.expand_child(ctx, expanded)
  return Loader.new(ctx.ui.bufnr):expand_child(ctx, expanded)
end

function M.close_all_tree(ctx, path, cursor_line_path)
  return Loader.new(ctx.ui.bufnr):close_all_tree(ctx, path, cursor_line_path)
end

function M.expand_parent(ctx, path, cursor_line_path, expanded)
  return Loader.new(ctx.ui.bufnr):expand_parent(ctx, path, cursor_line_path, expanded)
end

function M.shrink(ctx, path, cursor_line_path)
  return Loader.new(ctx.ui.bufnr):shrink(ctx, path, cursor_line_path)
end

function M.reload(ctx)
  return Loader.new(ctx.ui.bufnr):reload()
end

function M.execute(action_name, range, opts, action_opts)
  local ctx, err = Context.get()
  if err ~= nil then
    return require("kivi.vendor.promise").reject(err)
  end

  local nodes = ctx.ui:selected_nodes(action_name, range)
  ctx.ui:reset_selections(action_name)
  return require("kivi.core.executor").new(ctx.ui):execute(ctx, nodes, action_name, opts, action_opts)
end

function M.open_renamer(base_node, rename_items, has_cut)
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

function M.open_creator(base_node)
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

return M
