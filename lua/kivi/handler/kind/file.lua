local filelib = require("kivi.lib.file")

local M = {}

M.opts = { expand_parent = { root_patterns = { ".git" } } }

local adjust_window = function()
  vim.cmd.wincmd("w")
end

function M.action_open(_, nodes)
  adjust_window()
  for _, node in ipairs(nodes) do
    filelib.open(node.path)
  end
end

function M.action_tab_open(_, nodes)
  for _, node in ipairs(nodes) do
    filelib.tab_open(node.path)
  end
end

function M.action_vsplit_open(_, nodes)
  adjust_window()
  for _, node in ipairs(nodes) do
    filelib.vsplit_open(node.path)
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
    local answer = self.input_reader:get(item.to.path .. " already exists, (f)orce (n)o (r)ename: ")
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

  return self.controller:reload(ctx):next(function()
    if #rename_items > 0 then
      return self.controller:open_renamer(base_node, rename_items, has_cut)
    end
  end)
end

function M.action_show_details(_, nodes)
  local paths = vim.tbl_map(function(node)
    return node.path
  end, nodes)
  return filelib
    .details(paths)
    :next(function(output)
      if #paths == 1 and filelib.is_dir(paths[1]) then
        local prefix = paths[1] .. ":\n"
        vim.api.nvim_echo({ { prefix }, { output } }, true, {})
      else
        vim.api.nvim_echo({ { output } }, true, {})
      end
    end)
    :catch(function(err)
      require("kivi.vendor.misclib.message").error(err)
    end)
end

function M.action_show_git_ignores(_, nodes, ctx)
  local first_node = nodes[1]
  if not first_node then
    return
  end

  local git_root, git_err = filelib.find_git_root()
  if git_err then
    return nil, git_err
  end

  local base_node = first_node:parent_or_root()
  local cmd = { "git", "-C", base_node.path, "ls-files", "--full-name" }
  return require("kivi.lib.job")
    .promise(cmd)
    :next(function(output)
      local paths = vim.split(output, "\n", true)

      local in_git = {}
      local pathlib = require("kivi.lib.path")
      for _, path in ipairs(paths) do
        in_git[pathlib.join(git_root, path)] = true
      end

      for _, node in ipairs(base_node.children) do
        if not in_git[node.path] and not filelib.is_dir(node.path) then
          node.is_git_ignored = true
        end
      end

      ctx.ui:redraw_buffer()
    end)
    :catch(function(err)
      require("kivi.vendor.misclib.message").error(err)
    end)
end

function M.create(_, path)
  return filelib.create(path)
end

function M.delete(_, path)
  return filelib.delete(path)
end

function M.rename(_, from, to)
  return filelib.rename(from, to)
end

function M.copy(_, from, to)
  return filelib.copy(from, to)
end

function M.exists(_, path)
  return filelib.exists(path)
end

function M.find_upward_marker(self)
  for _, pattern in ipairs(self.action_opts.root_patterns) do
    local found = filelib.find_upward_dir(pattern)
    if found ~= nil then
      return filelib.adjust(found)
    end
  end
  return filelib.adjust(".")
end

return M
