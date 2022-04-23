local pathlib = require("kivi.lib.path")
local Path = require("kivi.lib.path").Path

local M = {}

M.opts = { yank = { key = "path", register = "+" } }

function M.action_parent(self, nodes, ctx)
  local node = nodes[1]
  if not node then
    return
  end
  return self.controller:navigate_parent(ctx, pathlib.parent(node:root().path:get()))
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
  return self.controller:back(ctx, path)
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
  local expanded = ctx.opts.expanded
  for _, node in ipairs(nodes) do
    local path = node.path:get()
    if expanded[path] then
      expanded[path] = nil
    else
      expanded[path] = true
    end
  end

  return self.controller:expand_child(ctx, expanded)
end

function M.action_close_all_tree(self, _, ctx)
  return self.controller:expand_child(ctx, {})
end

function M.action_create(self, nodes)
  local node = nodes[1]
  if not node then
    return
  end
  local base_node = node:parent_or_root()
  return self.controller:open_creator(base_node)
end

function M.action_rename(self, nodes)
  local node = nodes[1]
  if not node then
    return
  end
  local base_node = node:root()
  if not base_node then
    return
  end

  local rename_items = vim.tbl_map(function(n)
    return { from = n.path }
  end, nodes)

  local has_cut = true
  return self.controller:open_renamer(base_node, rename_items, has_cut)
end

function M.action_delete(self, nodes, ctx)
  local yes = self:confirm("delete?", nodes)
  if not yes then
    self.messagelib.info("canceled.")
    return
  end

  for _, node in ipairs(nodes) do
    self:delete(node.path)
  end
  return self.controller:reload(ctx)
end

function M.action_expand_parent(self, nodes, ctx)
  local node = nodes[1]
  if not node then
    return
  end

  local bottom = node:parent_or_root()
  local above_path = self:find_upward_marker()
  local paths = bottom.path:between(above_path)

  local expanded = {}
  for _, path in ipairs(paths) do
    expanded[path:get()] = true
  end

  return self.controller:expand_parent(ctx, above_path, node.path:get(), expanded)
end

function M.find_upward_marker(_)
  return Path.new("/")
end

function M.action_shrink(self, nodes, ctx)
  local node = nodes[1]
  if not node then
    return
  end
  local parent = node:parent_or_root()
  return self.controller:shrink(ctx, parent.path, node.path:get())
end

return M
