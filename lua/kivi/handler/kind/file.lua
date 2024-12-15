local filelib = require("kivi.lib.file")

local M = {}

M.opts = { expand_parent = { root_patterns = { ".git" } } }

local adjust_window = function()
  vim.cmd.wincmd("w")
end

function M.action_open(nodes)
  adjust_window()
  for _, node in ipairs(nodes) do
    filelib.open(node.path)
  end
end

function M.action_tab_open(nodes)
  for _, node in ipairs(nodes) do
    filelib.tab_open(node.path)
  end
end

function M.action_vsplit_open(nodes)
  adjust_window()
  for _, node in ipairs(nodes) do
    filelib.vsplit_open(node.path)
  end
end

M.action_child = M.action_open

function M.action_open_by_system_default(nodes)
  local promises = vim
    .iter(nodes)
    :map(function(node)
      return M.open_by_system_default(node.path)
    end)
    :totable()
  return require("kivi.vendor.promise").all(promises)
end

--- @param nodes KiviNode[]
--- @param ctx KiviContext
function M.action_paste(nodes, _, ctx)
  local node = nodes[1]
  if not node then
    return
  end
  local base_node = node:parent_or_root()

  local copied, has_cut = ctx.clipboard:peek()
  if #copied == 0 then
    require("kivi.lib.message").info("No copied files.")
    return
  end

  local already_exists = {}
  vim.iter(copied):each(function(old_node)
    local new_node = old_node:move_to(base_node)
    if M.exists(new_node.path) then
      table.insert(already_exists, { from = old_node, to = new_node })
      return
    end

    if has_cut then
      M.rename(old_node.path, new_node.path)
    else
      M.copy(old_node.path, new_node.path)
    end
  end)

  local canceled_items = {}
  local overwrite_items = {}
  local rename_items = {}
  local input_reader = require("kivi.lib.input").reader()
  vim.iter(already_exists):each(function(item)
    local answer = input_reader:get(item.to.path .. " already exists, (f)orce (n)o (r)ename: ")
    if answer == "r" then
      table.insert(rename_items, { from = item.from.path, to = item.to.path })
      return
    end
    if answer == "f" then
      table.insert(overwrite_items, item)
      return
    end
    table.insert(canceled_items, item)
  end)

  for _, item in ipairs(overwrite_items) do
    if has_cut then
      M.rename(item.from.path, item.to.path)
    else
      M.copy(item.from.path, item.to.path)
    end
  end

  if #canceled_items ~= #copied then
    ctx.clipboard:clear()
  elseif #canceled_items > 0 then
    require("kivi.lib.message").info("Canceled.")
  end

  return require("kivi.controller").reload(ctx):next(function()
    if #rename_items > 0 then
      return require("kivi.controller").open_renamer(base_node, rename_items, has_cut)
    end
  end)
end

function M.action_show_details(nodes)
  local paths = vim
    .iter(nodes)
    :map(function(node)
      return node.path
    end)
    :totable()
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
      require("kivi.lib.message").warn(err)
    end)
end

function M.create(path)
  return filelib.create(path)
end

function M.delete(path)
  return filelib.delete(path)
end

function M.rename(from, to)
  return filelib.rename(from, to)
end

function M.copy(from, to)
  return filelib.copy(from, to)
end

function M.exists(path)
  return filelib.exists(path)
end

function M.find_upward_marker(action_ctx)
  local root = vim.fs.root(assert(vim.uv.cwd()), action_ctx.opts.root_patterns)
  return filelib.adjust(root or ".")
end

function M.open_by_system_default(path)
  local cmd
  if vim.fn.has("mac") == 1 then
    cmd = { "open", path }
  elseif vim.fn.has("wsl") == 1 then
    cmd = { "wslview", path }
  elseif vim.fn.has("win32") == 1 then
    cmd = { "cmd.exe", "/c", "start", path }
  elseif vim.fn.has("linux") == 1 then
    cmd = { "xdg-open", path }
  end
  if not cmd then
    return require("kivi.vendor.promise").reject("no cmd to open by system default")
  end
  return require("kivi.lib.job").promise(cmd):catch(function(err)
    require("kivi.lib.message").warn(err)
  end)
end

return M
