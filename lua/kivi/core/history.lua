local M = {}

local History = {}
History.__index = History
M.History = History

function History.new()
  local tbl = {_rows = {}, _paths = {}, latest_path = nil}
  return setmetatable(tbl, History)
end

function History.add(self, path)
  vim.validate({path = {path, "string"}, latest_path = {self.latest_path, "string"}})
  self:store_current()
  table.insert(self._paths, self.latest_path)
end

function History.store_current(self)
  vim.validate({latest_path = {self.latest_path, "string"}})
  self._rows[self.latest_path] = vim.api.nvim_win_get_cursor(0)[1]
end

function History.set(self, path)
  vim.validate({path = {path, "string"}})
  self.latest_path = path
end

function History.pop(self)
  return table.remove(self._paths)
end

function History.stored(self, path)
  vim.validate({path = {path, "string"}})
  return self._rows[path]
end

return M
