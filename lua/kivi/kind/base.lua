local M = {}

M.opts = {yank = {key = "path", register = "+"}}

M.behaviors = {}

M.action_debug_print = function(_, nodes)
  for _, node in ipairs(nodes) do
    print(vim.inspect(node))
  end
end

M.action_yank = function(self, nodes)
  local values = vim.tbl_map(function(node)
    return node[self.action_opts.key]
  end, nodes)
  local value = table.concat(values, "\n")
  if value ~= "" then
    vim.fn.setreg(self.action_opts.register, value)
    print("yank: " .. value)
  end
end

M.__index = M
setmetatable(M, {})

return M
