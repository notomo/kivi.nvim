local M = {}

M.error = function(err)
  vim.api.nvim_err_write("[kivi] " .. err .. "\n")
end

M._echo = function(msg, strs, hl_group)
  strs = strs or {}
  if #strs <= 1 then
    vim.api.nvim_command("echohl " .. hl_group)
    vim.api.nvim_command(([[echomsg "[kivi] %s %s"]]):format(msg, table.concat(strs, " ")))
    vim.api.nvim_command("echohl None")
    return
  end
  vim.api.nvim_command("echohl " .. hl_group)
  vim.api.nvim_command(([[echomsg "[kivi] %s\n%s"]]):format(msg, table.concat(strs, "\n")))
  vim.api.nvim_command("echohl None")
end

M.info = function(msg, strs)
  M._echo(msg, strs, "None")
end

M.warn = function(err, strs)
  M._echo(err, strs, "WarningMsg")
end

return M
