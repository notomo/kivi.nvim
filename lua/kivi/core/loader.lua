local Context = require("kivi.core.context").Context
local Collector = require("kivi.core.collector").Collector

local M = {}

local LoadOption = {}
LoadOption.__index = LoadOption
M.LoadOption = LoadOption

function LoadOption.new(raw_opts)
  local tbl = vim.tbl_extend("force", {back = false, expand = false, target_path = nil}, raw_opts or {})
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

function Loader.load(self, ctx)
  return self:_load(ctx, LoadOption.new({}))
end

function Loader.reload(self, raw_load_opts, raw_opts)
  local ctx, err = Context.get(self._bufnr)
  if err ~= nil then
    return nil, err
  end
  ctx.opts = ctx.opts:merge(raw_opts or {})
  return self:_load(ctx, LoadOption.new(raw_load_opts))
end

function Loader.back(self, ctx, path)
  ctx.opts = ctx.opts:merge({path = path})
  return self:_load(ctx, LoadOption.new({back = true}))
end

function Loader.expand(self, ctx, expanded)
  ctx.opts.expanded = expanded
  return self:_load(ctx, LoadOption.new({expand = true}))
end

function Loader._load(_, ctx, load_opts)
  local result, err = Collector.new(ctx.source):start(ctx.opts)
  if err ~= nil then
    return nil, err
  end

  local root, ok = result:get()
  if ok then
    ctx.history:add(root.path:get(), load_opts.back)
    ctx.ui = ctx.ui:redraw(root, ctx.source, ctx.history, ctx.opts, load_opts)
    ctx.history:set(root.path:get(), load_opts.expand)
    ctx.source:hook(root.path)
  end

  return result, nil
end

return M
