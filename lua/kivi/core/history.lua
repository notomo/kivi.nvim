local persist = require("kivi/lib/_persist")("history")
persist.histories = persist.histories or {}

local M = {}

local History = {}
History.__index = History

function History.add(self)
  if self.latest_path ~= nil then
    self._paths[self.latest_path] = vim.api.nvim_win_get_cursor(0)[1]
  end
end

function History.set(self, path)
  self.latest_path = path
end

function History.restore(self, current_path)
  local row = self._paths[current_path]
  if row ~= nil then
    vim.api.nvim_win_set_cursor(0, {row, 0})
  end
end

M.create = function(key)
  local history = persist.histories[key]
  if history ~= nil then
    return history
  end

  local tbl = {_paths = {}, latest_path = nil}
  local self = setmetatable(tbl, History)
  persist.histories[key] = self
  return self
end

return M
