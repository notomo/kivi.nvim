local File = require("kivi/lib/file").File
local highlights = require("kivi/lib/highlight")
local vim = vim

local M = {}

M.collect = function(self, opts)
  local dir = File.new(opts.path:get())
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

M.highlight = function(self, bufnr, nodes, opts)
  local highlighter = self.highlights:reset(bufnr)
  highlighter:filter("KiviDirectory", nodes, function(node)
    return node.kind_name == "directory"
  end)
  highlighter:filter("KiviDirectoryOpen", nodes, function(node)
    return node.kind_name == "directory" and opts.expanded[node.path:get()]
  end)
end

M.init_path = function(self)
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

M.hook = function(_, path)
  vim.cmd("silent lcd " .. path:get())
end

M.kind_name = "file"

return M
