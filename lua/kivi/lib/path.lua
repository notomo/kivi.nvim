local M = {}

function M.join(...)
  return vim.fs.joinpath(...)
end

function M.normalize(...)
  return vim.fs.normalize(...)
end

function M.slash(path)
  if vim.endswith(path, "/") then
    return path
  end
  return path .. "/"
end

function M.relative(base, path)
  base = M.slash(base)
  if not vim.startswith(path, base) then
    return path
  end
  return path:sub(#base + 1)
end

function M._depth(path)
  return #(vim.split(path, "/", { plain = true }))
end

function M.between(path, base_path)
  local dir
  if vim.endswith(path, "/") then
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

function M.parent(path)
  path = M.normalize(path)
  if vim.endswith(path, "/") then
    local index = path:reverse():find("/", 2) or 0
    path = path:sub(1, #path - index + 1)
    return path
  end
  local index = path:reverse():find("/") or 0
  path = path:sub(1, #path - index + 1)
  return path
end

function M.tail(path)
  path = M.normalize(path)
  if not vim.endswith(path, "/") then
    local factors = vim.split(path, "/", { plain = true })
    return factors[#factors]
  end
  local factors = vim.split(path:sub(1, #path - 1), "/", { plain = true })
  return factors[#factors] .. "/"
end

function M.trim_slash(path)
  path = M.normalize(path)
  if not vim.endswith(path, "/") or path == "/" then
    return path
  end
  return path:sub(1, #path - 1)
end

return M
