local M = {}
M.__index = M

local adjust_window = function()
  vim.api.nvim_command("wincmd w")
end

M.action_open = function(_, nodes)
  adjust_window()
  for _, node in ipairs(nodes) do
    node.path:open()
  end
end

M.action_tab_open = function(_, nodes)
  for _, node in ipairs(nodes) do
    node.path:tab_open()
  end
end

M.action_vsplit_open = function(_, nodes)
  adjust_window()
  for _, node in ipairs(nodes) do
    node.path:vsplit_open()
  end
end

M.action_child = M.action_open

M.action_delete = function(self, nodes, ctx)
  local yes = self:confirm("delete?", nodes)
  if not yes then
    self.messagelib.info("canceled.")
    return
  end

  for _, node in ipairs(nodes) do
    node.path:delete()
  end
  self:start_path({expanded = ctx.opts.expanded, expand = true})
end

M.action_paste = function(self, nodes, ctx)
  local target = nodes[1]
  if target == nil then
    return
  end
  local base_node = target:parent_or_root()

  local already_exists = {}
  local copied, has_cut = ctx.clipboard:pop()
  for _, old_node in ipairs(copied) do
    local new_node = old_node:move_to(base_node)
    if new_node.path:exists() then
      table.insert(already_exists, {from = old_node, to = new_node})
      goto continue
    end

    if has_cut then
      old_node.path:rename(new_node.path)
    else
      old_node.path:copy(new_node.path)
    end

    ::continue::
  end

  local overwrite_items = {}
  local rename_items = {}
  for _, item in ipairs(already_exists) do
    local answer = self.input_reader:get(item.to.path:get() .. " already exists, (f)orce (n)o (r)ename: ")
    if answer == "n" then
      goto continue
    elseif answer == "r" then
      table.insert(rename_items, {from = item.from.path, to = item.to.path})
    elseif answer == "f" then
      table.insert(overwrite_items, item)
    end
    ::continue::
  end

  for _, item in ipairs(overwrite_items) do

    if has_cut then
      item.from.path:rename(item.to.path)
    else
      item.from.path:copy(item.to.path)
    end
  end

  self:start_path({expanded = ctx.opts.expanded, expand = true})

  if #rename_items > 0 then
    self:start_renamer(base_node, rename_items, has_cut)
  end
end

M.action_create = function(self, nodes)
  local target = nodes[1]
  if target == nil then
    return
  end
  local base_node = target:parent_or_root()
  self:start_creator(base_node)
end

M.action_rename = function(self, nodes)
  local target = nodes[1]
  if target == nil then
    return
  end
  local base_node = target:root()
  if base_node == nil then
    return
  end

  local rename_items = vim.tbl_map(function(node)
    return {from = node.path}
  end, nodes)

  local has_cut = true
  self:start_renamer(base_node, rename_items, has_cut)
end

M.rename = function(_, items, has_cut)
  local success = {}
  local already_exists = {}
  for i, item in ipairs(items) do
    if item.to:exists() then
      table.insert(already_exists, item)
      goto continue
    end

    if has_cut then
      item.from:rename(item.to)
    else
      item.from:copy(item.to)
    end

    success[i] = item
    ::continue::
  end
  return {success = success, already_exists = already_exists}
end

M.create = function(_, paths)
  local success = {}
  local already_exists = {}
  for i, path in ipairs(paths) do
    if path:exists() then
      table.insert(already_exists, path)
      goto continue
    end

    path:create()

    success[i] = path
    ::continue::
  end
  return {success = success, already_exists = already_exists}
end

return M
