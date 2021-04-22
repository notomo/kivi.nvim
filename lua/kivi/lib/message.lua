local M = {}

function M.error(err)
  vim.api.nvim_err_write("[kivi] " .. err .. "\n")
end

function M._echo(msg, strs, hl_group)
  strs = strs or {}
  if #strs <= 1 then
    local str = ("[kivi] %s %s"):format(msg, table.concat(strs, " "))
    return vim.api.nvim_echo({{str, hl_group}}, true, {})
  end

  local str = table.concat(strs, "\n")
  vim.api.nvim_echo({{"[kivi] " .. msg .. "\n", hl_group}, {str, hl_group}}, true, {})
end

function M.info(msg, strs)
  M._echo(msg, strs)
end

function M.warn(err, strs)
  M._echo(err, strs, "WarningMsg")
end

return M
