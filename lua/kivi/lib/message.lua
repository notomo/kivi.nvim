local M = {}

M.error = function(err)
  vim.api.nvim_err_write("[kivi] " .. err .. "\n")
end

return M
