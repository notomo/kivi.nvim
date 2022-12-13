local pathlib = require("kivi.lib.path")

local M = {}

M.opts = { yank = { key = "path", register = "+" } }

function M.action_parent(_, nodes, ctx)
  local node = nodes[1]
  if not node then
    return
  end
  return require("kivi.controller").navigate_parent(ctx, pathlib.parent(node:root().path))
end

function M.action_debug_print(_, nodes)
  for _, node in ipairs(nodes) do
    require("kivi.vendor.misclib.message").info(node:raw())
  end
end

function M.action_yank(self, nodes)
  local values = vim.tbl_map(function(node)
    return tostring(node[self.action_opts.key])
  end, nodes)
  if #values ~= 0 then
    vim.fn.setreg(self.action_opts.register, table.concat(values, "\n"))
    require("kivi.lib.message").info("yank:", values)
  end
end

function M.action_back(_, _, ctx)
  local path = ctx.history:pop()
  if not path then
    return
  end
  return require("kivi.controller").back(ctx, path)
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

function M.action_toggle_tree(_, nodes, ctx)
  local expanded = ctx.opts.expanded
  for _, node in ipairs(nodes) do
    local path = node.path
    if expanded[path] then
      expanded[path] = nil
    else
      expanded[path] = true
    end
  end

  return require("kivi.controller").expand_child(ctx, expanded)
end

function M.action_close_all_tree(_, nodes, ctx)
  local node = nodes[1]
  if not node then
    return
  end
  local parent = node:parent_or_root()
  return require("kivi.controller").close_all_tree(ctx, parent.path, node.path)
end

function M.action_create(_, nodes)
  local node = nodes[1]
  if not node then
    return
  end
  local base_node = node:parent_or_root()
  return require("kivi.controller").open_creator(base_node)
end

function M.action_rename(_, nodes)
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
  return require("kivi.controller").open_renamer(base_node, rename_items, has_cut)
end

function M.action_delete(self, nodes, ctx)
  local yes = require("kivi.util.input").confirm("delete?", nodes)
  if not yes then
    require("kivi.lib.message").info("canceled.")
    return
  end

  for _, node in ipairs(nodes) do
    self:delete(node.path)
  end
  return require("kivi.controller").reload(ctx)
end

function M.action_expand_parent(self, nodes, ctx)
  local node = nodes[1]
  if not node then
    return
  end

  local bottom = node:parent_or_root()
  local above_path = self:find_upward_marker()
  local paths = pathlib.between(bottom.path, above_path)

  local expanded = {}
  for _, path in ipairs(paths) do
    expanded[path] = true
  end

  return require("kivi.controller").expand_parent(ctx, above_path, node.path, expanded)
end

function M.find_upward_marker(_)
  return pathlib.adjust("/")
end

function M.action_shrink(_, nodes, ctx)
  local node = nodes[1]
  if not node then
    return
  end
  local parent = node:parent_or_root()
  return require("kivi.controller").shrink(ctx, parent.path, node.path)
end

return M
