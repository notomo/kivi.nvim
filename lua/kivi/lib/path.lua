local M = require("kivi.vendor.misclib.path")

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
  return #(vim.split(path, "/", true))
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

return M
