local repository = require("kivi.lib.repository").Repository.new("context")
local History = require("kivi.core.history").History
local Clipboard = require("kivi.core.clipboard").Clipboard

local M = {}

local Context = {}
Context.__index = Context
M.Context = Context

function Context.new(source, ui, key, opts)
  local tbl = {
    ui = ui,
    source = source,
    opts = opts,
    history = History.new(key),
    clipboard = Clipboard.new(source.name),
    _key = key,
  }
  local self = setmetatable(tbl, Context)
  if not repository:get(key) then
    vim.cmd(([[autocmd BufWipeout <buffer=%s> lua require("kivi.command").Command.new("cleanup", %s)]]):format(ui.bufnr, ui.bufnr))
  end
  repository:set(key, self)
  return self
end

function Context.delete(self)
  repository:delete(self._key)
  self.history:delete()
end

function Context.get(bufnr)
  vim.validate({bufnr = {bufnr, "number", true}})
  local path = vim.api.nvim_buf_get_name(bufnr or 0)
  local key = path:match("kivi://(.+)/kivi")
  if key == nil then
    return nil, "not matched path: " .. path
  end
  local ctx = repository:get(key)
  if ctx == nil then
    return nil, "no context: " .. path
  end
  return ctx, nil
end

return M

