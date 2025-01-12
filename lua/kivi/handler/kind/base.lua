local pathlib = require("kivi.lib.path")

local M = {}

M.opts = { yank = { key = "path", register = "+" } }

--- @param nodes KiviNode[]
--- @param ctx KiviContext
function M.action_parent(nodes, _, ctx)
  local node = nodes[1]
  if not node then
    return
  end
  return require("kivi.controller").navigate_parent(ctx, pathlib.parent(node:root().path))
end

--- @param nodes KiviNode[]
function M.action_debug_print(nodes)
  for _, node in ipairs(nodes) do
    require("kivi.lib.message").info(node:raw())
  end
end

--- @param nodes KiviNode[]
function M.action_yank(nodes, action_ctx)
  local values = vim
    .iter(nodes)
    :map(function(node)
      return tostring(node[action_ctx.opts.key])
    end)
    :totable()
  if #values ~= 0 then
    vim.fn.setreg(action_ctx.opts.register, table.concat(values, "\n"))
    require("kivi.lib.message").info_with("yank:", values)
  end
end

--- @param ctx KiviContext
function M.action_back(_, _, ctx)
  local path = ctx.history:pop()
  if not path then
    return
  end
  return require("kivi.controller").back(ctx, path)
end

--- @param ctx KiviContext
function M.action_toggle_selection(nodes, _, ctx)
  ctx.ui:toggle_selections(nodes)
end

--- @param ctx KiviContext
function M.action_copy(nodes, _, ctx)
  ctx.clipboard:copy(nodes)
end

--- @param ctx KiviContext
function M.action_cut(nodes, _, ctx)
  ctx.clipboard:cut(nodes)
end

--- @param ctx KiviContext
function M.action_clear_clipboard(_, _, ctx)
  ctx.clipboard:clear()
  require("kivi.lib.message").info("Cleared clipboard.")
end

--- @param nodes KiviNode[]
--- @param ctx KiviContext
function M.action_toggle_tree(nodes, _, ctx)
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

--- @param nodes KiviNode[]
--- @param ctx KiviContext
function M.action_close_all_tree(nodes, _, ctx)
  local node = nodes[1]
  if not node then
    return
  end
  local parent = node:parent_or_root()
  return require("kivi.controller").close_all_tree(ctx, parent.path, node.path)
end

--- @param nodes KiviNode[]
function M.action_create(nodes)
  local node = nodes[1]
  if not node then
    return
  end
  local base_node = node:parent_or_root()
  return require("kivi.controller").open_creator(base_node)
end

--- @param nodes KiviNode[]
function M.action_rename(nodes)
  local node = nodes[1]
  if not node then
    return
  end
  local base_node = node:root()
  if not base_node then
    return
  end

  local rename_items = vim
    .iter(nodes)
    :map(function(n)
      return { from = n.path }
    end)
    :totable()

  local has_cut = true
  return require("kivi.controller").open_renamer(base_node, rename_items, has_cut)
end

--- @param nodes KiviNode[]
--- @param ctx KiviContext
function M.action_delete(nodes, action_ctx, ctx)
  local yes = require("kivi.util.input").confirm("delete?", nodes)
  if not yes then
    require("kivi.lib.message").info("canceled.")
    return
  end

  return require("kivi.vendor.promise")
    .all(vim
      .iter(nodes)
      :map(function(node)
        return action_ctx.kind.delete(node.path)
      end)
      :totable())
    :next(function()
      return require("kivi.controller").reload(ctx)
    end)
end

--- @param nodes KiviNode[]
--- @param ctx KiviContext
function M.action_expand_parent(nodes, action_ctx, ctx)
  local node = nodes[1]
  if not node then
    return
  end

  local bottom = node:parent_or_root()
  local above_path = action_ctx.kind.find_upward_marker(action_ctx)
  local paths = pathlib.between(bottom.path, above_path)

  local expanded = {}
  for _, path in ipairs(paths) do
    expanded[path] = true
  end

  return require("kivi.controller").expand_parent(ctx, above_path, node.path, expanded)
end

function M.find_upward_marker(_)
  return pathlib.normalize("/")
end

--- @param nodes KiviNode[]
--- @param ctx KiviContext
function M.action_shrink(nodes, _, ctx)
  local node = nodes[1]
  if not node then
    return
  end
  local parent = node:parent_or_root()
  return require("kivi.controller").shrink(ctx, parent.path, node.path)
end

return M
