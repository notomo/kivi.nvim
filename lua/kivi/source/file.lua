local File = require("kivi.lib.file").File
local highlights = require("kivi.lib.highlight")
local filelib = require("kivi.lib.file")
local vim = vim

local M = {}

function M.collect(self, opts)
  local dir_path = M.Target.new(self.opts.target, self.opts.root_patterns):path() or opts.path:get()
  local dir = File.new(dir_path)
  if not dir:is_dir() then
    return nil, "does not exist: " .. opts.path:get()
  end

  local paths, err = dir:paths()
  if err ~= nil then
    return nil, err
  end

  table.sort(paths, function(a, b)
    local is_dir_a = a:is_dir() and 1 or 0
    local is_dir_b = b:is_dir() and 1 or 0
    if is_dir_a ~= is_dir_b then
      return is_dir_a > is_dir_b
    end
    return a:get() < b:get()
  end)

  local root = {value = dir:head(), path = dir:slash(), kind_name = "directory", children = {}}
  for _, path in ipairs(paths) do
    local value
    local kind_name = M.kind_name
    if path:is_dir() then
      value = path:slash():head()
      kind_name = "directory"
    else
      value = path:head()
    end

    local child = {value = value, path = path, kind_name = kind_name}
    if kind_name == "directory" and opts.expanded[path:get()] then
      child.children = self:collect(opts:merge({path = path})).children
    end

    table.insert(root.children, child)
  end
  return root
end

vim.cmd("highlight default link KiviDirectory String")
highlights.default("KiviDirectoryOpen", {
  ctermfg = {"KiviDirectory", 150},
  guifg = {"KiviDirectory", "#a9dd9d"},
  gui = "bold",
})

function M.highlight(self, bufnr, nodes, opts)
  local highlighter = self.highlights:reset(bufnr)
  highlighter:filter("KiviDirectory", nodes, function(node)
    return node.kind_name == "directory"
  end)
  highlighter:filter("KiviDirectoryOpen", nodes, function(node)
    return node.kind_name == "directory" and opts.expanded[node.path:get()]
  end)
end

function M.init_path(self)
  local bufnr = self.bufnr
  if vim.bo[bufnr].filetype == self.filetype then
    return
  end

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local path = File.new(vim.api.nvim_buf_get_name(bufnr))
  if not path:readable() then
    return
  end

  return path:get()
end

function M.hook(_, path)
  vim.cmd("silent lcd " .. path:get())
end

M.kind_name = "file"

M.opts = {target = "current", root_patterns = {".git"}}

local Target = {}
Target.__index = Target
M.Target = Target

function Target.new(name, root_patterns)
  vim.validate({name = {name, "string"}})
  local tbl = {_name = name, _root_patterns = root_patterns}
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
