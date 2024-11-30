local Context = require("kivi.core.context")

local M = {}

--- @param ctx KiviContext
function M.open(ctx, initial_bufnr, source_setup_opts)
  return ctx.source:start(ctx.opts, source_setup_opts):next(function(nodes)
    ctx.ui:redraw(nodes)
    local _ = ctx.ui:move_cursor(ctx.history, ctx.source.init_path(initial_bufnr)) or ctx.ui:init_cursor()
    ctx.history:set(nodes.root_path)
    ctx.source:hook(nodes, ctx.ui.bufnr)
  end)
end

--- @param ctx KiviContext
--- @param path string
--- @param source_setup_opts table?
function M.navigate(ctx, path, source_setup_opts)
  ctx.opts = ctx.opts:merge({ path = path })
  return ctx.source:start(ctx.opts, source_setup_opts):next(function(nodes)
    ctx.history:add(nodes.root_path)
    ctx.ui:redraw(nodes)
    local _ = ctx.ui:restore_cursor(ctx.history, nodes.root_path) or ctx.ui:init_cursor()
    ctx.history:set(nodes.root_path)
    ctx.source:hook(nodes, ctx.ui.bufnr)
  end)
end

--- @param ctx KiviContext
function M.navigate_parent(ctx, path)
  ctx.opts = ctx.opts:merge({ path = path })
  return ctx.source:start(ctx.opts):next(function(nodes)
    ctx.history:add(nodes.root_path)
    ctx.ui:redraw(nodes)
    if nodes.root_path ~= ctx.history.latest_path then
      local _ = ctx.ui:move_cursor(ctx.history, ctx.history.latest_path) or ctx.ui:init_cursor()
    end
    ctx.history:set(nodes.root_path)
    ctx.source:hook(nodes, ctx.ui.bufnr)
  end)
end

--- @param bufnr integer
--- @param cursor_line_path string?
--- @param expanded table?
function M.reload(bufnr, cursor_line_path, expanded)
  local ctx = Context.get(bufnr)
  if type(ctx) == "string" then
    local err = ctx
    return require("kivi.vendor.promise").reject(err)
  end
  ctx.opts = ctx.opts:merge({ expanded = expanded or ctx.opts.expanded })

  local unlock = function() end
  if cursor_line_path then
    unlock = ctx:lock_last_position(cursor_line_path)
  end

  return ctx.source:start(ctx.opts):next(function(nodes)
    ctx.ui:redraw(nodes)
    ctx.ui:move_cursor(ctx.history, cursor_line_path)
    unlock()
    ctx.source:hook(nodes, ctx.ui.bufnr)
  end)
end

--- @param ctx KiviContext
function M.back(ctx, path)
  ctx.opts = ctx.opts:merge({ path = path })
  return ctx.source:start(ctx.opts):next(function(nodes)
    ctx.history:store_current()
    ctx.ui:redraw(nodes)
    ctx.ui:restore_cursor(ctx.history, nodes.root_path)
    ctx.history:set(nodes.root_path)
    ctx.source:hook(nodes, ctx.ui.bufnr)
  end)
end

--- @param ctx KiviContext
function M.expand_child(ctx, expanded)
  ctx.opts.expanded = expanded
  return ctx.source:start(ctx.opts):next(function(nodes)
    ctx.ui:redraw(nodes)
    ctx.source:hook(nodes, ctx.ui.bufnr)
  end)
end

--- @param ctx KiviContext
function M.close_all_tree(ctx, path, cursor_line_path)
  ctx.opts = ctx.opts:merge({ path = path })
  ctx.opts.expanded = {}
  return ctx.source:start(ctx.opts):next(function(nodes)
    ctx.ui:redraw(nodes)
    ctx.ui:move_cursor(ctx.history, cursor_line_path)
    ctx.source:hook(nodes, ctx.ui.bufnr)
  end)
end

--- @param ctx KiviContext
--- @param path string
--- @param cursor_line_path string?
function M.shrink(ctx, path, cursor_line_path)
  ctx.opts = ctx.opts:merge({ path = path })
  return ctx.source:start(ctx.opts):next(function(nodes)
    ctx.history:add(nodes.root_path)
    ctx.ui:redraw(nodes)
    ctx.ui:move_cursor(ctx.history, cursor_line_path)
    ctx.history:set(nodes.root_path)
    ctx.source:hook(nodes, ctx.ui.bufnr)
  end)
end

--- @param ctx KiviContext
function M.expand_parent(ctx, path, cursor_line_path, expanded)
  ctx.opts = ctx.opts:merge({ path = path, expanded = expanded })
  return ctx.source:start(ctx.opts):next(function(nodes)
    ctx.ui:redraw(nodes)
    ctx.ui:move_cursor(ctx.history, cursor_line_path)
    ctx.history:set(nodes.root_path)
    ctx.source:hook(nodes, ctx.ui.bufnr)
  end)
end

return M
