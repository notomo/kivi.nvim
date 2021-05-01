local cursorlib = require("kivi.lib.cursor")

local M = {}

local Cursor = {}
Cursor.__index = Cursor
M.Cursor = Cursor

function Cursor.new(row, window_id, bufnr)
  vim.validate({row = {row, "number"}, window_id = {window_id, "number"}, bufnr = {bufnr, "number"}})
  local tbl = {_row = row, _window_id = window_id, _bufnr = bufnr}
  return setmetatable(tbl, Cursor)
end

function Cursor.restore(self)
  cursorlib.set_row(self._row, self._window_id, self._bufnr)
end

return M
