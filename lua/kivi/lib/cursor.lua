local M = {}

local get_row = function(row, bufnr)
  local count = vim.api.nvim_buf_line_count(bufnr or 0)
  if row > count then
    return count
  end
  return row
end

M.set_row = function(row, window_id, bufnr)
  vim.api.nvim_win_set_cursor(window_id or 0, {get_row(row, bufnr), 0})
end

M.set = function(row, col, window_id, bufnr)
  vim.api.nvim_win_set_cursor(window_id or 0, {get_row(row, bufnr), col})
end

return M
