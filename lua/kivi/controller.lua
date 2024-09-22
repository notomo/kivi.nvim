local Context = require("kivi.core.context")
local loader = require("kivi.core.loader")

local M = {}

function M.open(raw_opts)
  local opts, open_opts = require("kivi.core.option").new(raw_opts)
  local source = require("kivi.core.source").new(opts.source, opts.source_opts)
  if type(source) == "string" then
    local err = source
    return require("kivi.vendor.promise").reject(err)
  end

  local initial_bufnr = vim.api.nvim_get_current_buf()
  local ui, key = require("kivi.view").open(source, open_opts)
  local ctx = Context.new(source, ui, key, opts)
  return loader.open(ctx, initial_bufnr, opts.source_setup_opts)
end

function M.navigate(ctx, path, source_setup_opts)
  return loader.navigate(ctx, path, source_setup_opts)
end

function M.navigate_parent(ctx, path)
  return loader.navigate_parent(ctx, path)
end

function M.back(ctx, path)
  return loader.back(ctx, path)
end

function M.expand_child(ctx, expanded)
  return loader.expand_child(ctx, expanded)
end

function M.close_all_tree(ctx, path, cursor_line_path)
  return loader.close_all_tree(ctx, path, cursor_line_path)
end

function M.expand_parent(ctx, path, cursor_line_path, expanded)
  return loader.expand_parent(ctx, path, cursor_line_path, expanded)
end

function M.shrink(ctx, path, cursor_line_path)
  return loader.shrink(ctx, path, cursor_line_path)
end

function M.reload(ctx)
  return loader.reload(ctx.ui.bufnr)
end

function M.execute(action_name, range, opts, action_opts)
  local ctx = Context.get()
  if type(ctx) == "string" then
    local err = ctx
    return require("kivi.vendor.promise").reject(err)
  end

  local nodes = ctx.ui:selected_nodes(action_name, range)
  ctx.ui:reset_selections(action_name)
  local result = require("kivi.core.executor").execute(ctx, nodes, action_name, opts, action_opts)
  if type(result) == "string" then
    local err = result
    return require("kivi.vendor.promise").reject(err)
  end
  return result
end

--- @param base_node KiviNode
function M.open_renamer(base_node, rename_items, has_cut)
  local ctx = Context.get()
  if type(ctx) == "string" then
    local err = ctx
    return err
  end

  local kind = base_node:kind()
  if type(kind) == "string" then
    local err = kind
    return err
  end

  require("kivi.view.renamer").open(kind, ctx.ui.bufnr, base_node, rename_items, has_cut)
end

--- @param base_node KiviNode
function M.open_creator(base_node)
  local ctx = Context.get()
  if type(ctx) == "string" then
    local err = ctx
    return err
  end

  local kind = base_node:kind()
  if type(kind) == "string" then
    local err = kind
    return err
  end

  require("kivi.view.creator").open(kind, ctx.ui.bufnr, base_node)
end

return M
