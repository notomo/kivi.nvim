local M = {}

local Path = {}
Path.__index = Path
M.Path = Path

function Path.new(path)
  if type(path) == "table" then
    path = path:get()
  end
  local tbl = { path = M.adjust_sep(path) }
  return setmetatable(tbl, Path)
end

function Path.__tostring(self)
  return self.path
end

function Path.get(self)
  return self.path
end

function M.join(...)
  local items = {}
  local slash = false
  for _, item in ipairs({ ... }) do
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

  return path
end

function Path.join(self, ...)
  return self.new(M.join(self.path, ...))
end

function M.parent(path)
  if vim.endswith(path, "/") then
    return vim.fn.fnamemodify(path, ":h:h")
  end
  return vim.fn.fnamemodify(path, ":h")
end

function Path.parent(self)
  return self.new(M.parent(self.path))
end

function M.slash(path)
  if vim.endswith(path, "/") then
    return path
  end
  return path .. "/"
end

function M.trim_slash(path)
  if not vim.endswith(path, "/") or path == "/" then
    return path
  end
  return path:sub(1, #path - 1)
end

function M.head(path)
  if not vim.endswith(path, "/") or path == "/" then
    return vim.fn.fnamemodify(path, ":t")
  end
  return vim.fn.fnamemodify(path, ":h:t") .. "/"
end

function M.relative(base, path)
  base = M.slash(base)
  if not vim.startswith(path, base) then
    return path
  end
  return path:sub(#base + 1)
end

function M._depth(path)
  return #(vim.split(path, "/", true))
end

function M.is_dir(path)
  return vim.endswith(path, "/")
end

function Path.between(self, base_path)
  local dir
  if M.is_dir(self.path) then
    dir = self
  else
    dir = self:parent()
  end

  local paths = {}
  local depth = M._depth(base_path:get())
  while true do
    if depth >= M._depth(dir:get()) then
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
