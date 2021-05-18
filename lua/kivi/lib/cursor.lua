local M = {}

local get_row = function(row, bufnr)
  local count = vim.api.nvim_buf_line_count(bufnr or 0)
  if row > count then
    return count
  end
  return row
end

function M.set_row(row, window_id, bufnr)
  vim.api.nvim_win_set_cursor(window_id or 0, {get_row(row, bufnr), 0})
end

function M.set(row, col, window_id, bufnr)
  vim.api.nvim_win_set_cursor(window_id or 0, {get_row(row, bufnr), col})
end

function M.set_row_by_buffer(row, bufnr)
  vim.validate({row = {row, "number"}, bufnr = {bufnr, "number"}})
  local ids = vim.fn.win_findbuf(bufnr)
  for _, id in ipairs(ids) do
    M.set_row(row, id, bufnr)
  end
end

return M
