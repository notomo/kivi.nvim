--- @class KiviHistory
--- @field latest_path string|nil
--- @field private _positions table<string,{cursor_row:integer,first_row:integer}>
--- @field private _paths string[]
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

--- @param path string
function History.add(self, path)
  self:store_current()
  if self.latest_path ~= path then
    table.insert(self._paths, self.latest_path)
  end
end

function History.store_current(self)
  self._positions[self.latest_path] = {
    cursor_row = vim.api.nvim_win_get_cursor(0)[1],
    first_row = vim.fn.line("w0"),
  }
end

--- @param path string
function History.set(self, path)
  self.latest_path = path
end

function History.pop(self)
  return table.remove(self._paths)
end

--- @param path string
function History.stored(self, path)
  return self._positions[path]
end

return History
