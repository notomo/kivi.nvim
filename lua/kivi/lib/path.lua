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

M.find_root = function(pattern)
  local file = vim.api.nvim_get_runtime_file("lua/" .. pattern, false)[1]
  if file == nil then
    return nil, "project root directory not found by pattern: " .. pattern
  end
  return vim.split(M.adjust_sep(file), "/lua/", true)[1], nil
end

if vim.fn.has("win32") == 1 then
  M.adjust_sep = function(path)
    return path:gsub("\\", "/")
  end
else
  M.adjust_sep = function(path)
    return path
  end
end

return M
