local M = {}

M.config = { opts = {} }

function M.set(config)
  M.config = vim.tbl_deep_extend("force", M.config, config)
end

return M
