local File = require("kivi.lib.file").File
local highlights = require("kivi.lib.highlight")
local filelib = require("kivi.lib.file")
local vim = vim

local M = {}

function M.collect(self, opts)
  local dir = File.new(opts.path:get())
  if not dir:is_dir() then
    return nil, "does not exist: " .. opts.path:get()
  end

  local entries, err = dir:entries()
  if err ~= nil then
    return nil, err
  end

  local root = { value = dir:head(), path = dir, kind_name = "directory", children = {} }
  for _, entry in ipairs(entries) do
    local kind_name = M.kind_name
    if entry.is_directory then
      kind_name = "directory"
    end

    local child = { value = entry.name, path = entry.path, kind_name = kind_name }
    if kind_name == "directory" and opts.expanded[entry.path:get()] then
      child.children = self:collect(opts:merge({ path = entry.path })).children
    end

    table.insert(root.children, child)
  end
  return root
end

vim.cmd("highlight default link KiviDirectory String")
highlights.default("KiviDirectoryOpen", {
  ctermfg = { "KiviDirectory", 150 },
  guifg = { "KiviDirectory", "#a9dd9d" },
  gui = "bold",
})

function M.highlight(self, bufnr, row, nodes, opts)
  local highlighter = self.highlights:create(bufnr)
  highlighter:filter("KiviDirectory", row, nodes, function(node)
    return node.kind_name == "directory"
  end)
  highlighter:filter("KiviDirectoryOpen", row, nodes, function(node)
    return node.kind_name == "directory" and opts.expanded[node.path:get()]
  end)
end

function M.init_path(self)
  local bufnr = self.bufnr
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  if vim.bo[bufnr].filetype == self.filetype then
    return
  end

  local path = File.new(vim.api.nvim_buf_get_name(bufnr))
  if not path:readable() then
    return
  end

  return path:get()
end

function M.hook(_, path)
  File.new(path):lcd()
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