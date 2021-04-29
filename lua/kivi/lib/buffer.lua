local vim = vim

local M = {}

function M.set_lines(bufnr, s, e, lines)
  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, s, e, false, lines)
  vim.bo[bufnr].modifiable = false
end

return M
