local Context = require("kivi.core.context").Context
local Collector = require("kivi.core.collector").Collector

local M = {}

local LoadOption = {}
LoadOption.__index = LoadOption
M.LoadOption = LoadOption

function LoadOption.new(raw_opts)
  local tbl = vim.tbl_extend("force", {cursor_line_path = nil}, raw_opts or {})
  return setmetatable(tbl, LoadOption)
end

local Loader = {}
Loader.__index = Loader
M.Loader = Loader

function Loader.new(bufnr)
  vim.validate({bufnr = {bufnr, "number"}})
  local tbl = {_bufnr = bufnr}
  return setmetatable(tbl, Loader)
end

function Loader.load(_, ctx, load_opts)
  load_opts = load_opts or LoadOption.new({})

  local result, err = Collector.new(ctx.source):start(ctx.opts)
  if err ~= nil then
    return nil, err
  end

  local root, ok = result:get()
  if ok then
    ctx.history:add(root.path:get())
    ctx.ui:redraw(root, ctx.source, ctx.history, ctx.opts, load_opts)
    ctx.history:set(root.path:get())
  end
  return result, nil
end

function Loader.reload(self, raw_load_opts, raw_opts)
  local ctx, err = Context.get(self._bufnr)
  if err ~= nil then
    return nil, err
  end

  ctx.opts = ctx.opts:merge(raw_opts or {})
  return self:load(ctx, LoadOption.new(raw_load_opts))
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
    ctx.ui:redraw(root, ctx.source, ctx.history, ctx.opts, LoadOption.new({}))
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
    ctx.history:add(root.path:get())

    local cursor = ctx.ui:save_cursor()
    ctx.ui:redraw(root, ctx.source, ctx.history, ctx.opts, LoadOption.new({}))
    cursor:restore()
  end
  return result, nil
end

return M
