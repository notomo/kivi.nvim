local M = {}

M.opts = {yank = {key = "path", register = "+"}}

M.behaviors = {}

M.action_parent = function(self, nodes)
  local node = nodes[1]
  if node == nil then
    return
  end
  local root = node:root()
  return self:start_path({path = root.path:parent()})
end

M.action_debug_print = function(_, nodes)
  for _, node in ipairs(nodes) do
    print(vim.inspect(node))
  end
end

M.action_yank = function(self, nodes)
  local values = vim.tbl_map(function(node)
    return tostring(node[self.action_opts.key])
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
  return self:start_path({path = path, back = true}, ctx.source_name)
end

M.action_toggle_selection = function(_, nodes, ctx)
  ctx.ui:toggle_selections(nodes)
end

M.action_copy = function(_, nodes, ctx)
  ctx.clipboard:copy(nodes)
end

M.action_cut = function(_, nodes, ctx)
  ctx.clipboard:cut(nodes)
end

M.action_toggle_tree = function(self, nodes, ctx)
  if nodes[1] == nil then
    return
  end

  local root = nodes[1]:root()
  local opts = ctx.opts:clone(root.path)
  opts.expand = true
  for _, node in ipairs(nodes) do
    local path = node.path:get()
    local already = opts.expanded[path]
    if already then
      opts.expanded[path] = nil
    else
      opts.expanded[path] = true
    end
  end

  return self:start_path(opts, ctx.source_name)
end

M.__index = M
setmetatable(M, {})

return M
