local cursorlib = require("kivi/lib/cursor")
local persist = require("kivi/lib/_persist")("history")
persist.histories = persist.histories or {}

local M = {}

local History = {}
History.__index = History

function History.add(self, is_back)
  if self.latest_path ~= nil then
    self._rows[self.latest_path] = vim.api.nvim_win_get_cursor(0)[1]
    if not is_back then
      table.insert(self._paths, self.latest_path)
    end
  end
end

function History.set(self, path)
  self.latest_path = path
end

function History.pop(self)
  return table.remove(self._paths)
end

function History.restore(self, current_path)
  local row = self._rows[current_path]
  if row ~= nil then
    cursorlib.set_row(row)
    return true
  end
  return false
end

M.create = function(key)
  local history = persist.histories[key]
  if history ~= nil then
    return history
  end

  local tbl = {_rows = {}, _paths = {}, latest_path = nil}
  local self = setmetatable(tbl, History)
  persist.histories[key] = self
  return self
end

return M
