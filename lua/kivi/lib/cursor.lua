local M = {}

local get_row = function(row)
  local count = vim.api.nvim_buf_line_count(0)
  if row > count then
    return count
  end
  return row
end

M.set_row = function(row)
  vim.api.nvim_win_set_cursor(0, {get_row(row), 0})
end

M.set = function(row, col)
  vim.api.nvim_win_set_cursor(0, {get_row(row), col})
end

return M
