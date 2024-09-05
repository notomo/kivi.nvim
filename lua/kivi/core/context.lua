local History = require("kivi.core.history")
local Clipboard = require("kivi.core.clipboard")

local _contexts = {}

--- @class KiviContext
--- @field opts KiviOptions
--- @field history KiviHistory
--- @field ui KiviView
--- @field source KiviSource
--- @field clipboard KiviClipboard
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
    _last_position = {
      locked = false,
      path = nil,
    },
  }
  local self = setmetatable(tbl, Context)
  if not _contexts[key] then
    vim.api.nvim_create_autocmd({ "BufWipeout" }, {
      buffer = ui.bufnr,
      callback = function()
        _contexts[key] = nil
      end,
    })

    vim.api.nvim_create_autocmd({ "CursorMoved" }, {
      buffer = ui.bufnr,
      callback = function()
        if self._last_position.locked then
          return
        end
        local node = self.ui:current_node() or {}
        self._last_position.path = node.path
      end,
    })
  end
  _contexts[key] = self
  return self
end

--- @param bufnr integer?
--- @return KiviContext|string
function Context.get(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr or 0)
  local key = path:match("^kivi://(.+)/kivi")
  if key == nil then
    return "not matched path: " .. path
  end

  local ctx = _contexts[key]
  if ctx == nil then
    return "no context: " .. path
  end

  return ctx
end

function Context.lock_last_position(self, path)
  self._last_position.locked = true
  self._last_position.path = path
  return function()
    self._last_position.locked = false
  end
end

function Context.last_position(self)
  return vim.deepcopy(self._last_position)
end

return Context
