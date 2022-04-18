local History = require("kivi.core.history")
local Clipboard = require("kivi.core.clipboard")

local _contexts = {}

local Context = {}
Context.__index = Context

function Context.new(source, ui, key, opts)
  local old_ctx = _contexts[key] or {}
  local tbl = {
    ui = ui,
    source = source,
    opts = opts,
    history = old_ctx.history or History.new(),
    clipboard = Clipboard.new(source.name),
  }
  local self = setmetatable(tbl, Context)
  if not _contexts[key] then
    vim.api.nvim_create_autocmd({ "BufWipeout" }, {
      buffer = ui.bufnr,
      callback = function()
        _contexts[key] = nil
      end,
    })
  end
  _contexts[key] = self
  return self
end

function Context.get(bufnr)
  vim.validate({ bufnr = { bufnr, "number", true } })
  local path = vim.api.nvim_buf_get_name(bufnr or 0)
  local key = path:match("^kivi://(.+)/kivi")
  if key == nil then
    return nil, "not matched path: " .. path
  end
  local ctx = _contexts[key]
  if ctx == nil then
    return nil, "no context: " .. path
  end
  return ctx, nil
end

return Context
