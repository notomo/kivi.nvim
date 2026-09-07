local Context = require("kivi.core.context")

local M = {}

--- @param ctx KiviContext
--- @async
function M.open(ctx, initial_bufnr)
  ctx.ui:set_busy()
  local nodes = ctx.source:start(ctx.opts)
  ctx.ui:redraw(nodes)
  local _ = ctx.ui:move_cursor(ctx.history, ctx.source.init_path(initial_bufnr)) or ctx.ui:init_cursor()
  ctx.history:set(nodes.root_path)
  ctx.source:hook({ nodes = nodes, bufnr = ctx.ui.bufnr })
end

--- @param ctx KiviContext
--- @param path string
--- @async
function M.navigate(ctx, path)
  ctx.opts = ctx.opts:merge({ path = path })

  ctx.ui:set_busy()
  local nodes = ctx.source:start(ctx.opts)
  ctx.history:add(nodes.root_path)
  ctx.ui:redraw(nodes)
  local _ = ctx.ui:restore_cursor(ctx.history, nodes.root_path) or ctx.ui:init_cursor()
  ctx.history:set(nodes.root_path)
  ctx.source:hook({ nodes = nodes, bufnr = ctx.ui.bufnr })
end

--- @param ctx KiviContext
--- @async
function M.navigate_parent(ctx, path)
  ctx.opts = ctx.opts:merge({ path = path })

  ctx.ui:set_busy()
  local nodes = ctx.source:start(ctx.opts)
  ctx.history:add(nodes.root_path)
  ctx.ui:redraw(nodes)
  if nodes.root_path ~= ctx.history.latest_path then
    local _ = ctx.ui:move_cursor(ctx.history, ctx.history.latest_path) or ctx.ui:init_cursor()
  end
  ctx.history:set(nodes.root_path)
  ctx.source:hook({ nodes = nodes, bufnr = ctx.ui.bufnr })
end

--- @param bufnr integer
--- @param cursor_line_path string?
--- @param expanded table?
--- @async
function M.reload(bufnr, cursor_line_path, expanded)
  local ctx = Context.get(bufnr)
  if type(ctx) == "string" then
    local err = ctx
    error(err, 0)
  end
  ctx.opts = ctx.opts:merge({ expanded = expanded or ctx.opts.expanded })

  local unlock = function() end
  if cursor_line_path then
    unlock = ctx:lock_last_position(cursor_line_path)
  end

  ctx.ui:set_busy()
  local nodes = ctx.source:start(ctx.opts)
  ctx.ui:redraw(nodes)
  ctx.ui:move_cursor(ctx.history, cursor_line_path)
  unlock()
  ctx.source:hook({ nodes = nodes, bufnr = ctx.ui.bufnr, reload = true })
end

--- @param ctx KiviContext
--- @async
function M.back(ctx, path)
  ctx.opts = ctx.opts:merge({ path = path })
  ctx.ui:set_busy()
  local nodes = ctx.source:start(ctx.opts)
  ctx.history:store_current()
  ctx.ui:redraw(nodes)
  ctx.ui:restore_cursor(ctx.history, nodes.root_path)
  ctx.history:set(nodes.root_path)
  ctx.source:hook({ nodes = nodes, bufnr = ctx.ui.bufnr })
end

--- @param ctx KiviContext
--- @async
function M.expand_child(ctx, expanded)
  ctx.opts.expanded = expanded
  ctx.ui:set_busy()
  local nodes = ctx.source:start(ctx.opts)
  ctx.ui:redraw(nodes)
  ctx.source:hook({ nodes = nodes, bufnr = ctx.ui.bufnr })
end

--- @param ctx KiviContext
--- @async
function M.close_all_tree(ctx, path, cursor_line_path)
  ctx.opts = ctx.opts:merge({ path = path })
  ctx.opts.expanded = {}
  ctx.ui:set_busy()
  local nodes = ctx.source:start(ctx.opts)
  ctx.ui:redraw(nodes)
  ctx.ui:move_cursor(ctx.history, cursor_line_path)
  ctx.source:hook({ nodes = nodes, bufnr = ctx.ui.bufnr })
end

--- @param ctx KiviContext
--- @param path string
--- @param cursor_line_path string?
--- @async
function M.shrink(ctx, path, cursor_line_path)
  ctx.opts = ctx.opts:merge({ path = path })
  ctx.ui:set_busy()
  local nodes = ctx.source:start(ctx.opts)
  ctx.history:add(nodes.root_path)
  ctx.ui:redraw(nodes)
  ctx.ui:move_cursor(ctx.history, cursor_line_path)
  ctx.history:set(nodes.root_path)
  ctx.source:hook({ nodes = nodes, bufnr = ctx.ui.bufnr })
end

--- @param ctx KiviContext
--- @async
function M.expand_parent(ctx, path, cursor_line_path, expanded)
  ctx.opts = ctx.opts:merge({ path = path, expanded = expanded })
  ctx.ui:set_busy()
  local nodes = ctx.source:start(ctx.opts)
  ctx.ui:redraw(nodes)
  ctx.ui:move_cursor(ctx.history, cursor_line_path)
  ctx.history:set(nodes.root_path)
  ctx.source:hook({ nodes = nodes, bufnr = ctx.ui.bufnr })
end

return M
