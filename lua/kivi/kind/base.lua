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

M.action_back = function(self, _, ctx)
  local path = ctx.history:pop()
  if path == nil then
    return
  end
  self:open_path(ctx.source_name, {path = path, layout = "no", back = true})
end

M.action_toggle_selection = function(_, nodes, ctx)
  ctx.ui:toggle_selections(nodes)
end

M.__index = M
setmetatable(M, {})

return M