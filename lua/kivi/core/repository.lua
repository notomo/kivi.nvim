local persist = require("kivi/lib/_persist")("repository")
local vim = vim

local M = {}

M.set = function(key, values)
  local new_values = {}
  for k, v in pairs(values) do
    new_values[k] = v
  end
  persist[key] = new_values
end

M.get = function(key)
  return persist[key] or {}
end

M.get_from_path = function(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr or 0)
  local key = path:match("kivi://(.+)/kivi")
  if key == nil then
    return nil, "not matched path: " .. path
  end

  return M.get(key), nil
end

return M
