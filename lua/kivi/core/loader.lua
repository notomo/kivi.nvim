local Context = require("kivi.core.context")
local Collector = require("kivi.core.collector")

local Loader = {}
Loader.__index = Loader

function Loader.new(bufnr)
  vim.validate({ bufnr = { bufnr, "number" } })
  local tbl = { _bufnr = bufnr }
  return setmetatable(tbl, Loader)
end

function Loader.open(_, ctx, source_setup_opts)
  return Collector.new(ctx.source):start(ctx.opts, function(nodes)
    ctx.ui:redraw(nodes)
    local _ = ctx.ui:move_cursor(ctx.history, ctx.source:init_path()) or ctx.ui:init_cursor()
    ctx.history:set(nodes.root_path)
    return ctx.ui.bufnr
  end, source_setup_opts)
end

function Loader.navigate(_, ctx, path, source_setup_opts)
  vim.validate({ source_setup_opts = { source_setup_opts, "table", true } })
  ctx.opts = ctx.opts:merge({ path = path })
  return Collector.new(ctx.source):start(ctx.opts, function(nodes)
    ctx.history:add(nodes.root_path)
    ctx.ui:redraw(nodes)
    local _ = ctx.ui:restore_cursor(ctx.history, nodes.root_path) or ctx.ui:init_cursor()
    ctx.history:set(nodes.root_path)
    return ctx.ui.bufnr
  end, source_setup_opts)
end

function Loader.navigate_parent(_, ctx, path)
  ctx.opts = ctx.opts:merge({ path = path })
  return Collector.new(ctx.source):start(ctx.opts, function(nodes)
    ctx.history:add(nodes.root_path)
    ctx.ui:redraw(nodes)
    if nodes.root_path ~= ctx.history.latest_path then
      local _ = ctx.ui:move_cursor(ctx.history, ctx.history.latest_path) or ctx.ui:init_cursor()
    end
    ctx.history:set(nodes.root_path)
    return ctx.ui.bufnr
  end)
end

function Loader.reload(self, cursor_line_path, expanded)
  vim.validate({
    cursor_line_path = { cursor_line_path, "string", true },
    expanded = { expanded, "table", true },
  })

  local ctx, ctx_err = Context.get(self._bufnr)
  if ctx_err ~= nil then
    return require("kivi.vendor.promise").reject(ctx_err)
  end
  ctx.opts = ctx.opts:merge({ expanded = expanded or ctx.opts.expanded })

  return Collector.new(ctx.source):start(ctx.opts, function(nodes)
    ctx.ui:redraw(nodes)
    ctx.ui:move_cursor(ctx.history, cursor_line_path)
    return ctx.ui.bufnr
  end)
end

function Loader.back(_, ctx, path)
  ctx.opts = ctx.opts:merge({ path = path })
  return Collector.new(ctx.source):start(ctx.opts, function(nodes)
    ctx.history:store_current()
    ctx.ui:redraw(nodes)
    ctx.ui:restore_cursor(ctx.history, nodes.root_path)
    ctx.history:set(nodes.root_path)
    return ctx.ui.bufnr
  end)
end

function Loader.expand_child(_, ctx, expanded)
  ctx.opts.expanded = expanded
  return Collector.new(ctx.source):start(ctx.opts, function(nodes)
    ctx.ui:redraw(nodes)
    return ctx.ui.bufnr
  end)
end

function Loader.close_all_tree(_, ctx, path, cursor_line_path)
  ctx.opts = ctx.opts:merge({ path = path })
  ctx.opts.expanded = {}
  return Collector.new(ctx.source):start(ctx.opts, function(nodes)
    ctx.ui:redraw(nodes)
    ctx.ui:move_cursor(ctx.history, cursor_line_path)
    return ctx.ui.bufnr
  end)
end

function Loader.shrink(_, ctx, path, cursor_line_path)
  vim.validate({ cursor_line_path = { cursor_line_path, "string", true } })
  ctx.opts = ctx.opts:merge({ path = path })
  return Collector.new(ctx.source):start(ctx.opts, function(nodes)
    ctx.history:add(nodes.root_path)
    ctx.ui:redraw(nodes)
    ctx.ui:move_cursor(ctx.history, cursor_line_path)
    ctx.history:set(nodes.root_path)
    return ctx.ui.bufnr
  end)
end

function Loader.expand_parent(_, ctx, path, cursor_line_path, expanded)
  ctx.opts = ctx.opts:merge({ path = path, expanded = expanded })
  return Collector.new(ctx.source):start(ctx.opts, function(nodes)
    ctx.ui:redraw(nodes)
    ctx.ui:move_cursor(ctx.history, cursor_line_path)
    ctx.history:set(nodes.root_path)
    return ctx.ui.bufnr
  end)
end

return Loader
