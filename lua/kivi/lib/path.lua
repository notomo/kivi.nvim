local M = {}

function M.adjust(path)
  return M.adjust_sep(path)
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

function M.parent(path)
  if vim.endswith(path, "/") then
    local index = path:reverse():find("/", 2) or 0
    path = path:sub(1, #path - index + 1)
    return path
  end
  local index = path:reverse():find("/") or 0
  path = path:sub(1, #path - index + 1)
  return path
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
  if not vim.endswith(path, "/") then
    local factors = vim.split(path, "/", true)
    return factors[#factors]
  end
  local factors = vim.split(path:sub(1, #path - 1), "/", true)
  return factors[#factors] .. "/"
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

function M.between(path, base_path)
  local dir
  if M.is_dir(path) then
    dir = path
  else
    dir = M.parent(path)
  end

  local paths = {}
  local depth = M._depth(base_path)
  while true do
    if depth >= M._depth(dir) then
      break
    end
    table.insert(paths, dir)
    dir = M.parent(dir)
  end

  return paths
end

if vim.loop.os_uname().version:match("Windows") then
  function M.adjust_sep(path)
    return path:gsub("\\", "/")
  end
else
  function M.adjust_sep(path)
    return path
  end
end

return M
