local vim = vim

local M = {}

M.collect = function(self, opts)
  local dir_path = vim.fn.fnamemodify(opts.path, ":p")
  if not self.filelib.is_directory(dir_path) then
    return nil, "does not exist: " .. opts.path
  end

  local paths = {}
  for _, path in ipairs(vim.fn.readdir(dir_path)) do
    local abs_path = vim.fn.fnamemodify(self.pathlib.join(opts.path, path), ":p:gs?\\?\\/?")
    table.insert(paths, abs_path)
  end

  table.sort(paths, function(a, b)
    local is_dir_a = vim.fn.isdirectory(a)
    local is_dir_b = vim.fn.isdirectory(b)
    if is_dir_a ~= is_dir_b then
      return is_dir_a > is_dir_b
    end
    return a < b
  end)

  local root = {
    value = ".",
    path = self.pathlib.add_trailing_slash(vim.fn.fnamemodify(opts.path, ":p:h")),
    kind_name = "directory",
    children = {},
  }
  for _, path in ipairs(paths) do
    local value
    local kind_name = M.kind_name
    if vim.fn.isdirectory(path) ~= 0 then
      value = self.pathlib.add_trailing_slash(vim.fn.fnamemodify(path, ":h:t"))
      kind_name = "directory"
    else
      value = vim.fn.fnamemodify(path, ":t")
    end
    table.insert(root.children, {value = value, path = path, kind_name = kind_name})
  end
  return root
end

vim.api.nvim_command("highlight default link KiviDirectory String")

M.highlight = function(self, bufnr, nodes)
  local highlighter = self.highlights:reset(bufnr)
  highlighter:filter("KiviDirectory", nodes, function(node)
    return node.kind_name == "directory"
  end)
end

M.init_path = function(self)
  local bufnr = self.bufnr
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local path = vim.api.nvim_buf_get_name(bufnr)
  if not self.filelib.readable(path) then
    return
  end

  return path
end

M.hook = function(_, path)
  vim.api.nvim_command("lcd " .. path)
end

M.kind_name = "file"

return M
