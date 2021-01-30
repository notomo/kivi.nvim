local M = {}

M.error = function(err)
  vim.api.nvim_err_write("[kivi] " .. err .. "\n")
end

M._echo = function(msg, strs, hl_group)
  strs = strs or {}
  if #strs <= 1 then
    local str = ("[kivi] %s %s"):format(msg, table.concat(strs, " "))
    return vim.api.nvim_echo({{str, hl_group}}, true, {})
  end

  local str = table.concat(strs, "\n")
  vim.api.nvim_echo({{"[kivi] " .. msg .. "\n", hl_group}, {str, hl_group}}, true, {})
end

M.info = function(msg, strs)
  M._echo(msg, strs)
end

M.warn = function(err, strs)
  M._echo(err, strs, "WarningMsg")
end

return M
