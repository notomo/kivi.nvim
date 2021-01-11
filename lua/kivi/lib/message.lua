local M = {}

M.error = function(err)
  vim.api.nvim_err_write("[kivi] " .. err .. "\n")
end

M._echo = function(msg, strs, hl_group)
  strs = strs or {}
  if #strs <= 1 then
    vim.cmd("echohl " .. hl_group)
    vim.cmd(([[echomsg "[kivi] %s %s"]]):format(msg, table.concat(strs, " ")))
    vim.cmd("echohl None")
    return
  end
  vim.cmd("echohl " .. hl_group)
  vim.cmd(([[echomsg "[kivi] %s"]]):format(msg))
  for _, str in ipairs(strs) do
    vim.cmd(([[echomsg "%s"]]):format(str))
  end
  vim.cmd("echohl None")
end

M.info = function(msg, strs)
  M._echo(msg, strs, "None")
end

M.warn = function(err, strs)
  M._echo(err, strs, "WarningMsg")
end

return M
