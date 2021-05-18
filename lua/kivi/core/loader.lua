local Context = require("kivi.core.context").Context
local Collector = require("kivi.core.collector").Collector

local M = {}

local Loader = {}
Loader.__index = Loader
M.Loader = Loader

function Loader.new(bufnr)
  vim.validate({bufnr = {bufnr, "number"}})
  local tbl = {_bufnr = bufnr}
  return setmetatable(tbl, Loader)
end

function Loader.open(_, ctx)
  local result, err = Collector.new(ctx.source):start(ctx.opts)
  if err ~= nil then
    return nil, err
  end

  local root, ok = result:get()
  if ok then
    ctx.ui:redraw(root)
    ctx.ui:init_cursor(ctx.source:init_path())
    ctx.source:hook(root.path)
    ctx.history:set(root.path:get())
  end
  return result, nil
end

function Loader.navigate(_, ctx)
  local result, err = Collector.new(ctx.source):start(ctx.opts)
  if err ~= nil then
    return nil, err
  end

  local root, ok = result:get()
  if ok then
    ctx.history:add(root.path:get())
    ctx.ui:redraw(root)
    ctx.ui:move_or_restore_cursor(ctx.history, root.path:get())
    ctx.source:hook(root.path)
    ctx.history:set(root.path:get())
  end
  return result, nil
end

function Loader.reload(self, cursor_line_path, expanded)
  vim.validate({
    cursor_line_path = {cursor_line_path, "string", true},
    expanded = {expanded, "table", true},
  })

  local ctx, ctx_err = Context.get(self._bufnr)
  if ctx_err ~= nil then
    return nil, ctx_err
  end
  ctx.opts = ctx.opts:merge({expanded = expanded or ctx.opts.expanded})

  local result, err = Collector.new(ctx.source):start(ctx.opts)
  if err ~= nil then
    return nil, err
  end

  local root, ok = result:get()
  if ok then
    ctx.ui:redraw(root)
    ctx.ui:move_cursor(cursor_line_path)
    ctx.source:hook(root.path)
  end
  return result, nil
end

function Loader.back(_, ctx, path)
  ctx.opts = ctx.opts:merge({path = path})
  local result, err = Collector.new(ctx.source):start(ctx.opts)
  if err ~= nil then
    return nil, err
  end

  local root, ok = result:get()
  if ok then
    ctx.history:add_current_row()
    ctx.ui:redraw(root)
    ctx.ui:restore_cursor(ctx.history, root.path:get())
    ctx.source:hook(root.path)
    ctx.history:set(root.path:get())
  end
  return result, nil
end

function Loader.expand(_, ctx, expanded)
  ctx.opts.expanded = expanded
  local result, err = Collector.new(ctx.source):start(ctx.opts)
  if err ~= nil then
    return nil, err
  end

  local root, ok = result:get()
  if ok then
    ctx.ui:redraw(root)
    ctx.source:hook(root.path)
  end
  return result, nil
end

return M
