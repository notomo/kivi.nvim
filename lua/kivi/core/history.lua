local cursorlib = require("kivi.lib.cursor")

local M = {}

local History = {}
History.__index = History
M.History = History

function History.new(key)
  vim.validate({key = {key, "string"}})
  local tbl = {_rows = {}, _paths = {}, latest_path = nil}
  return setmetatable(tbl, History)
end

function History.add(self, path)
  vim.validate({path = {path, "string"}})
  if self.latest_path == nil or self.latest_path == path then
    return
  end
  self:add_current_row()
  table.insert(self._paths, self.latest_path)
end

function History.add_current_row(self)
  if self.latest_path == nil then
    return
  end
  self._rows[self.latest_path] = vim.api.nvim_win_get_cursor(0)[1]
end

function History.set(self, path)
  vim.validate({path = {path, "string"}})
  self.latest_path = path
end

function History.pop(self)
  return table.remove(self._paths)
end

function History.restore(self, path, window_id, bufnr)
  vim.validate({
    path = {path, "string"},
    window_id = {window_id, "number"},
    bufnr = {bufnr, "number"},
  })
  local row = self._rows[path]
  if row ~= nil then
    cursorlib.set_row(row, window_id, bufnr)
    return true
  end
  return false
end

return M
