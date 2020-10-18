local M = {}

M.opts = {}
M.behaviors = {}

M.action_debug_print = function(_, items)
  for _, item in ipairs(items) do
    print(vim.inspect(item))
  end
end

M.__index = M
setmetatable(M, {})

return M
