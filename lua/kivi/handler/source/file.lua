local filelib = require("kivi.lib.file")
local Promise = require("kivi.vendor.promise")

local M = {}

local collect
collect = function(target_dir, opts_expanded)
  target_dir = filelib.adjust(target_dir)
  return Promise.new(function(resolve, reject)
    local sender
    sender = vim.loop.new_async(function(v)
      local decoded = vim.mpack.decode(v)
      if decoded.error then
        reject(decoded.error)
      else
        resolve(decoded.root, decoded.expand_indicies)
      end
      sender:close()
    end)

    vim.loop.new_thread(function(async, dir, _expanded)
      local f = function()
        local expanded = vim.mpack.decode(_expanded)
        local entries, err = require("kivi.lib.file").entries(dir)
        if err then
          return async:send(vim.mpack.encode({ error = err }))
        end
        local root = {
          value = require("kivi.lib.path").head(dir),
          path = dir,
          kind_name = "directory",
          children = {},
        }
        local expand_indicies = {}
        for i, entry in ipairs(entries) do
          local kind_name = "file"
          if entry.is_directory then
            kind_name = "directory"
          end

          local path = entry.path
          local child = {
            value = entry.name,
            path = path,
            kind_name = kind_name,
            is_broken = entry.is_broken_link,
            is_link = entry.is_link,
            real_path = entry.real_path,
          }
          if child.kind_name == "directory" and expanded[child.path] then
            table.insert(expand_indicies, i)
          end
          table.insert(root.children, child)
        end

        async:send(vim.mpack.encode({ expand_indicies = expand_indicies, root = root }))
      end
      local ok, err = xpcall(f, debug.traceback)
      if not ok then
        error(err)
      end
    end, sender, target_dir, vim.mpack.encode(opts_expanded))
  end):next(function(root, expand_indicies)
    local promises = {}
    for _, i in ipairs(expand_indicies) do
      local child = root.children[i]
      table.insert(
        promises,
        collect(child.path, opts_expanded):next(function(result)
          root.children[i].children = result.children
        end)
      )
    end
    return Promise.all(promises):next(function()
      return root
    end)
  end)
end

function M.collect(_, opts)
  local dir = filelib.adjust(opts.path)
  if not filelib.is_dir(dir) then
    return Promise.reject("does not exist: " .. dir)
  end
  return collect(dir, opts.expanded)
end

local highlightlib = require("kivi.vendor.misclib.highlight")
highlightlib.link("KiviDirectory", "String")
highlightlib.link("KiviBrokenLink", "WarningMsg")
highlightlib.define("KiviDirectoryOpen", {
  fg = vim.api.nvim_get_hl_by_name("KiviDirectory", true).foreground,
  bold = true,
})

function M.highlight_one(_, decorator, row, node, opts)
  if node.kind_name == "directory" then
    decorator:highlight_line("KiviDirectory", row)
  end
  if node.kind_name == "directory" and opts.expanded[node.path] then
    decorator:highlight_line("KiviDirectoryOpen", row)
  end
  if node.is_broken then
    decorator:highlight_line("KiviBrokenLink", row)
  end
  if node.is_link then
    decorator:add_virtual_text(row, 0, { { "-> " .. node.real_path, "Comment" } })
  end
  if node.is_git_ignored then
    decorator:highlight_line("Comment", row)
    decorator:add_virtual_text(row, 0, { { "[X]", "Comment" } })
  end
end

function M.init_path(self)
  local bufnr = self.bufnr
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local path = vim.api.nvim_buf_get_name(bufnr)
  if not filelib.readable(path) then
    return
  end

  return filelib.adjust(path)
end

function M.hook(_, path, bufnr)
  if not filelib.exists(path) then
    return
  end

  local window_id = vim.fn.win_findbuf(bufnr)[1]
  if not window_id then
    return
  end

  vim.api.nvim_win_call(window_id, function()
    filelib.lcd(path)
  end)
end

M.kind_name = "file"
M.opts = {}
M.setup_opts = { target = "current", root_patterns = { ".git" } }

function M.setup(_, opts, setup_opts)
  local path = M.Target.new(setup_opts.target, setup_opts.root_patterns):path()
  return opts:merge({ path = path })
end

local Target = {}
Target.__index = Target
M.Target = Target

function Target.new(name, root_patterns)
  vim.validate({ name = { name, "string" } })
  local tbl = { _name = name, _root_patterns = root_patterns }
  return setmetatable(tbl, Target)
end

function Target.path(self)
  local f = self[self._name]
  if f == nil then
    return nil
  end
  return f(self)
end

function Target.project(self)
  for _, pattern in ipairs(self._root_patterns) do
    local found = filelib.find_upward_dir(pattern)
    if found ~= nil then
      return found
    end
  end
  return "."
end

function Target.current()
  return nil
end

return M
