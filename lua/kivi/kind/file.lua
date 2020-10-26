local M = {}
M.__index = M

local adjust_window = function()
  vim.api.nvim_command("wincmd w")
end

M.action_open = function(self, nodes)
  adjust_window()
  for _, node in ipairs(nodes) do
    self.filelib.open(node.path)
  end
end

M.action_tab_open = function(self, nodes)
  for _, node in ipairs(nodes) do
    self.filelib.tab_open(node.path)
  end
end

M.action_vsplit_open = function(self, nodes)
  adjust_window()
  for _, node in ipairs(nodes) do
    self.filelib.vsplit_open(node.path)
  end
end

M.action_child = M.action_open

M.action_parent = function(self, nodes)
  local node = nodes[1]
  if node == nil then
    return
  end
  local root = node:root()
  self:start_path({path = self.pathlib.add_trailing_slash(vim.fn.fnamemodify(root.path, ":h:h"))})
end

M.action_delete = function(self, nodes)
  local yes = self:confirm("delete?", nodes)
  if not yes then
    return
  end

  for _, node in ipairs(nodes) do
    self.filelib.delete(node.path)
  end
  self:start_path()
end

M.action_paste = function(self, nodes, ctx)
  local target = nodes[1]
  if target == nil then
    return
  end
  local base_node = target.parent
  if base_node == nil then
    return
  end

  local already_exists = {}
  local copied, has_cut = ctx.clipboard:pop()
  for _, old_node in ipairs(copied) do
    local new_node = old_node:move_to(base_node)
    if self.filelib.exists(new_node.path) then
      table.insert(already_exists, {from = old_node, to = new_node})
      goto continue
    end

    if has_cut then
      self.filelib.rename(old_node.path, new_node.path)
    else
      self.filelib.copy(old_node.path, new_node.path)
    end

    ::continue::
  end

  local overwrite_items = {}
  local rename_items = {}
  for _, item in ipairs(already_exists) do
    local answer = self.input_reader:get(item.to.path .. " already exists, (f)orce (n)o (r)ename: ")
    if answer == "n" then
      goto continue
    elseif answer == "r" then
      table.insert(rename_items, item)
    elseif answer == "f" then
      table.insert(overwrite_items, item)
    end
    ::continue::
  end

  for _, item in ipairs(overwrite_items) do
    if has_cut then
      self.filelib.rename(item.from.path, item.to.path)
    else
      self.filelib.copy(item.from.path, item.to.path)
    end
  end

  self:start_path()

  if #rename_items > 0 then
    self:start_renamer(base_node, rename_items, has_cut)
  end
end

return M
