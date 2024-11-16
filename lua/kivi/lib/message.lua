local M = {}

local plugin_name = vim.split((...):gsub("%.", "/"), "/", { plain = true })[1]
local prefix = ("[%s] "):format(plugin_name)

local echo = function(msg, strs, hl_group)
  strs = strs or {}
  msg = prefix .. msg
  if #strs <= 1 then
    local str = ("%s %s"):format(msg, table.concat(strs, " "))
    return vim.api.nvim_echo({ { str, hl_group } }, true, {})
  end

  local str = table.concat(strs, "\n")
  vim.api.nvim_echo({ { msg .. "\n", hl_group }, { str, hl_group } }, true, {})
end

function M.info_with(msg, strs)
  echo(msg, strs)
end

function M.warn_with(err, strs)
  echo(err, strs, "WarningMsg")
end

function M.warn(msg)
  vim.notify(M.wrap(msg), vim.log.levels.WARN)
end

function M.info(msg)
  vim.notify(M.wrap(msg))
end

function M.wrap(msg)
  if type(msg) == "string" then
    return prefix .. msg
  end
  return prefix .. vim.inspect(msg)
end

return M
