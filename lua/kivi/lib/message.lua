local M = {}

local plugin_name = vim.split((...):gsub("%.", "/"), "/", true)[1]
local prefix = ("[%s] "):format(plugin_name)

function M.error(err)
  error(prefix .. err)
end

local echo = function(msg, strs, hl_group)
  strs = strs or {}
  msg = prefix .. msg
  if #strs <= 1 then
    local str = ("%s %s"):format(msg, table.concat(strs, " "))
    return vim.api.nvim_echo({{str, hl_group}}, true, {})
  end

  local str = table.concat(strs, "\n")
  vim.api.nvim_echo({{msg .. "\n", hl_group}, {str, hl_group}}, true, {})
end

function M.info(msg, strs)
  echo(msg, strs)
end

function M.warn(err, strs)
  echo(err, strs, "WarningMsg")
end

return M
