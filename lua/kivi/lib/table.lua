local M = {}

function M.extend(default, ...)
  default = vim.deepcopy(default)
  local new_tbl = {}
  local keys = vim.tbl_keys(default)
  for _, tbl in ipairs({ ... }) do
    for _, key in ipairs(keys) do
      local value = tbl[key]
      if value then
        new_tbl[key] = value
      end
    end
  end
  return vim.tbl_extend("keep", new_tbl, default)
end

return M
