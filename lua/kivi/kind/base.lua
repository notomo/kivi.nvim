local M = {}

M.opts = {}
M.behaviors = {}

M.action_debug_print = function(_, nodes)
  for _, node in ipairs(nodes) do
    print(vim.inspect(node))
  end
end

M.__index = M
setmetatable(M, {})

return M
