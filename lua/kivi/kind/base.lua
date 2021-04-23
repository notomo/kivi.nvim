local M = {}

M.opts = {yank = {key = "path", register = "+"}}

M.behaviors = {}

function M.action_parent(self, nodes)
  local node = nodes[1]
  if node == nil then
    return
  end
  local root = node:root()
  return self:start_path({path = root.path:parent()})
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
  if path == nil then
    return
  end
  return self:start_path({path = path, back = true}, ctx.source_name)
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
  if nodes[1] == nil then
    return
  end

  local root = nodes[1]:root()
  local opts = ctx.opts:merge({path = root.path})
  for _, node in ipairs(nodes) do
    local path = node.path:get()
    local already = opts.expanded[path]
    if already then
      opts.expanded[path] = nil
    else
      opts.expanded[path] = true
    end
  end

  return self:start_path({expanded = opts.expanded, expand = true}, ctx.source_name)
end

return M
