local repository = require("kivi.lib.repository").Repository.new("context")
local History = require("kivi.core.history")
local Clipboard = require("kivi.core.clipboard")

local Context = {}
Context.__index = Context

function Context.new(source, ui, key, opts)
  local old_ctx = repository:get(key) or {}
  local tbl = {
    ui = ui,
    source = source,
    opts = opts,
    history = old_ctx.history or History.new(),
    clipboard = Clipboard.new(source.name),
    _key = key,
  }
  local self = setmetatable(tbl, Context)
  if not repository:get(key) then
    vim.api.nvim_create_autocmd({ "BufWipeout" }, {
      buffer = ui.bufnr,
      callback = function()
        repository:delete(self._key)
      end,
    })
  end
  repository:set(key, self)
  return self
end

function Context.get(bufnr)
  vim.validate({ bufnr = { bufnr, "number", true } })
  local path = vim.api.nvim_buf_get_name(bufnr or 0)
  local key = path:match("^kivi://(.+)/kivi")
  if key == nil then
    return nil, "not matched path: " .. path
  end
  local ctx = repository:get(key)
  if ctx == nil then
    return nil, "no context: " .. path
  end
  return ctx, nil
end

return Context
