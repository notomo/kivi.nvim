local M = {}

M.opts = {yank = {key = "path", register = "+"}}

M.behaviors = {}

function M.action_parent(self, nodes, ctx)
  local node = nodes[1]
  if not node then
    return
  end
  return self:navigate(ctx, node:root().path:parent())
end

function M.action_debug_print(_, nodes)
  for _, node in ipairs(nodes) do
    print(vim.inspect(node))
  end
end

function M.action_yank(self, nodes)
  local values = vim.tbl_map(function(node)
    return tostring(node[self.action_opts.key])
  end, nodes)
  if #values ~= 0 then
    vim.fn.setreg(self.action_opts.register, table.concat(values, "\n"))
    self.messagelib.info("yank:", values)
  end
end

function M.action_back(self, _, ctx)
  local path = ctx.history:pop()
  if not path then
    return
  end
  return self:back(ctx, path)
end

function M.action_toggle_selection(_, nodes, ctx)
  ctx.ui:toggle_selections(nodes)
end

function M.action_copy(_, nodes, ctx)
  ctx.clipboard:copy(nodes)
end

function M.action_cut(_, nodes, ctx)
  ctx.clipboard:cut(nodes)
end

function M.action_toggle_tree(self, nodes, ctx)
  if not nodes[1] then
    return
  end

  local expanded = ctx.opts.expanded
  for _, node in ipairs(nodes) do
    local path = node.path:get()
    if expanded[path] then
      expanded[path] = nil
    else
      expanded[path] = true
    end
  end

  return self:expand(ctx, expanded)
end

function M.action_close_all_tree(self, _, ctx)
  return self:expand(ctx, {})
end

return M
