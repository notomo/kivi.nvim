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
    return vim.fn.fnamemodify(path, ":h:h") .. "/"
  end
  local parent = vim.fn.fnamemodify(path, ":h")
  if vim.endswith(parent, "/") then
    return parent
  end
  return parent .. "/"
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
