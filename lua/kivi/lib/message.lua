local M = {}

M.error = function(err)
  vim.api.nvim_err_write("[kivi] " .. err .. "\n")
end

M.warn = function(err, strs)
  if #strs <= 1 then
    vim.api.nvim_command("echohl WarningMsg")
    vim.api.nvim_command(([[echomsg "[kivi] %s %s"]]):format(err, table.concat(strs, " ")))
    vim.api.nvim_command("echohl None")
    return
  end
  vim.api.nvim_command("echohl WarningMsg")
  vim.api.nvim_command(([[echomsg "[kivi] %s\n%s"]]):format(err, table.concat(strs, "\n")))
  vim.api.nvim_command("echohl None")
end

return M
