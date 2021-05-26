local M = {}

local Path = {}
Path.__index = Path
M.Path = Path

function Path.new(path)
  if type(path) == "table" then
    path = path:get()
  end
  local tbl = {path = M.adjust_sep(path)}
  return setmetatable(tbl, Path)
end

function Path.__tostring(self)
  return self.path
end

function Path.get(self)
  return self.path
end

function Path.join(self, ...)
  local items = {}
  local slash = false
  for _, item in ipairs({self.path, ...}) do
    if vim.endswith(item, "/") then
      item = item:sub(1, #item - 1)
      slash = true
    else
      slash = false
    end
    table.insert(items, item)
  end

  local path = table.concat(items, "/")
  if slash then
    path = path .. "/"
  end

  return self.new(path)
end

function Path.parent(self)
  if vim.endswith(self.path, "/") then
    return self.new(vim.fn.fnamemodify(self.path, ":h:h"))
  end
  return self.new(vim.fn.fnamemodify(self.path, ":h"))
end

function Path.slash(self)
  if vim.endswith(self.path, "/") then
    return self.new(self.path)
  end
  return self.new(self.path .. "/")
end

function Path.trim_slash(self)
  if not vim.endswith(self.path, "/") or self.path == "/" then
    return self.new(self.path)
  end
  return self.new(self.path:sub(1, #self.path - 1))
end

function Path.head(self)
  if not vim.endswith(self.path, "/") or self.path == "/" then
    return vim.fn.fnamemodify(self.path, ":t")
  end
  return vim.fn.fnamemodify(self.path, ":h:t") .. "/"
end

function Path.relative(self, path)
  local base = self:slash():get()
  if not vim.startswith(path:get(), base) then
    return path
  end
  return path:get():sub(#base + 1)
end

function Path.depth(self)
  return #(vim.split(self.path, "/", true))
end

function Path.is_dir(self)
  return vim.endswith(self.path, "/")
end

function Path.between(self, base_path)
  local dir
  if self:is_dir() then
    dir = self
  else
    dir = self:parent()
  end

  local paths = {}
  local depth = base_path:depth()
  while true do
    if depth >= dir:depth() then
      break
    end
    table.insert(paths, dir)
    dir = dir:parent()
  end

  return paths
end

if vim.fn.has("win32") == 1 then
  function M.adjust_sep(path)
    return path:gsub("\\", "/")
  end
else
  function M.adjust_sep(path)
    return path
  end
end

return M
