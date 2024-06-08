--- @class KiviHistory
--- @field latest_path string|nil
local History = {}
History.__index = History

function History.new()
  local tbl = {
    _positions = {},
    _paths = {},
    latest_path = nil,
  }
  return setmetatable(tbl, History)
end

function History.add(self, path)
  vim.validate({ path = { path, "string" }, latest_path = { self.latest_path, "string" } })
  self:store_current()
  if self.latest_path ~= path then
    table.insert(self._paths, self.latest_path)
  end
end

function History.store_current(self)
  vim.validate({ latest_path = { self.latest_path, "string" } })
  self._positions[self.latest_path] = {
    cursor_row = vim.api.nvim_win_get_cursor(0)[1],
    first_row = vim.fn.line("w0"),
  }
end

function History.set(self, path)
  vim.validate({ path = { path, "string" } })
  self.latest_path = path
end

function History.pop(self)
  return table.remove(self._paths)
end

function History.stored(self, path)
  vim.validate({ path = { path, "string" } })
  return self._positions[path]
end

return History
