local M = {}

function M.close(id)
  if not vim.api.nvim_win_is_valid(id) then
    return
  end
  vim.api.nvim_win_close(id, true)
end

function M.close_by_buffer(bufnr)
  local id = M.get_current_or_first(bufnr)
  if id then
    M.close(id)
  end
end

--- @param bufnr integer
function M.get_current_or_first(bufnr)
  local ids = vim.fn.win_findbuf(bufnr)
  local current = vim.api.nvim_get_current_win()
  for _, id in ipairs(ids) do
    if id == current then
      return id
    end
  end
  return ids[1]
end

return M
