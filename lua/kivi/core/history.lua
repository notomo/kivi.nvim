local cursorlib = require("kivi/lib/cursor")
local persist = {histories = {}}

local M = {}

local History = {}
History.__index = History
M.History = History

function History.new(key)
  vim.validate({key = {key, "string"}})
  local history = persist.histories[key]
  if history ~= nil then
    return history
  end

  local tbl = {_rows = {}, _paths = {}, latest_path = nil}
  local self = setmetatable(tbl, History)
  persist.histories[key] = self
  return self
end

function History.add(self, path, is_back, is_expand)
  vim.validate({
    path = {path, "string"},
    is_back = {is_back, "boolean"},
    is_expand = {is_expand, "boolean"},
  })
  if self.latest_path == nil or self.latest_path == path then
    return
  end

  self._rows[self.latest_path] = vim.api.nvim_win_get_cursor(0)[1]
  if not is_back then
    table.insert(self._paths, self.latest_path)
  end
end

function History.set(self, path, is_expand)
  vim.validate({path = {path, "string"}, is_expand = {is_expand, "boolean"}})
  if not is_expand then
    self.latest_path = path
  end
end

function History.pop(self)
  return table.remove(self._paths)
end

function History.restore(self, path)
  vim.validate({path = {path, "string"}})
  local row = self._rows[path]
  if row ~= nil then
    cursorlib.set_row(row)
    return true
  end
  return false
end

return M
