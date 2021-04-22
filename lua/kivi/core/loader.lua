local repository = require("kivi.core.repository")
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

function Loader.load(self, new_ctx, target_path, opts)
  vim.validate({new_ctx = {new_ctx, "table", true}, target_path = {target_path, "string", true}})
  local ctx, err
  if new_ctx ~= nil then
    ctx = new_ctx
  else
    ctx, err = repository.get_from_path(self._bufnr)
  end
  if err ~= nil then
    return nil, err
  end

  if opts ~= nil then
    ctx.opts = ctx.opts:merge(opts)
  end

  local result, start_err = Collector.new(ctx.source):start(ctx.opts)
  if start_err ~= nil then
    return nil, start_err
  end

  local root, ok = result:get()
  if ok then
    ctx.history:add(root.path:get(), ctx.opts.back)
    ctx.ui = ctx.ui:redraw(root, ctx.source, ctx.history, ctx.opts, target_path)
    ctx.history:set(root.path:get(), ctx.opts.expand)
    ctx.source:hook(root.path)
    -- TODO: else job
  end

  ctx.opts.expand = false
  ctx.opts.back = false
  ctx.opts.new = false

  return result, nil
end

return M
