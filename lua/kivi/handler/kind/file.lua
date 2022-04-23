local filelib = require("kivi.lib.file")
local File = require("kivi.lib.file").File

local M = {}

M.opts = { expand_parent = { root_patterns = { ".git" } } }

local adjust_window = function()
  vim.cmd("wincmd w")
end

function M.action_open(_, nodes)
  adjust_window()
  for _, node in ipairs(nodes) do
    filelib.open(node.path:get())
  end
end

function M.action_tab_open(_, nodes)
  for _, node in ipairs(nodes) do
    filelib.tab_open(node.path:get())
  end
end

function M.action_vsplit_open(_, nodes)
  adjust_window()
  for _, node in ipairs(nodes) do
    filelib.vsplit_open(node.path:get())
  end
end

M.action_child = M.action_open

function M.action_paste(self, nodes, ctx)
  local node = nodes[1]
  if not node then
    return
  end
  local base_node = node:parent_or_root()

  local already_exists = {}
  local copied, has_cut = ctx.clipboard:pop()
  for _, old_node in ipairs(copied) do
    local new_node = old_node:move_to(base_node)
    if self:exists(new_node.path) then
      table.insert(already_exists, { from = old_node, to = new_node })
      goto continue
    end

    if has_cut then
      self:rename(old_node.path, new_node.path)
    else
      self:copy(old_node.path, new_node.path)
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
      table.insert(rename_items, { from = item.from.path, to = item.to.path })
    elseif answer == "f" then
      table.insert(overwrite_items, item)
    end
    ::continue::
  end

  for _, item in ipairs(overwrite_items) do
    if has_cut then
      self:rename(item.from.path, item.to.path)
    else
      self:copy(item.from.path, item.to.path)
    end
  end

  local _, err = self.controller:reload(ctx)
  if err ~= nil then
    return nil, err
  end

  if #rename_items > 0 then
    return self.controller:open_renamer(base_node, rename_items, has_cut)
  end
end

function M.create(_, path)
  return filelib.create(path:get())
end

function M.delete(_, path)
  return filelib.delete(path:get())
end

function M.rename(_, from, to)
  return filelib.rename(from:get(), to:get())
end

function M.copy(_, from, to)
  return filelib.copy(from:get(), to:get())
end

function M.exists(_, path)
  return filelib.exists(path:get())
end

function M.find_upward_marker(self)
  for _, pattern in ipairs(self.action_opts.root_patterns) do
    local found = filelib.find_upward_dir(pattern)
    if found ~= nil then
      return File.new(found)
    end
  end
  return File.new(".")
end

return M
