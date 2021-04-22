local persist = {}
local vim = vim

local M = {}

function M.set(key, values)
  persist[key] = values
end

function M.get(key)
  return persist[key] or {}
end

function M.get_from_path(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr or 0)
  local key = path:match("kivi://(.+)/kivi")
  if key == nil then
    return nil, "not matched path: " .. path
  end

  return M.get(key), nil
end

return M
