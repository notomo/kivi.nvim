local M = {}

M.relative_modifier = function(base_path)
  local pattern = "^" .. M.adjust_sep(base_path):gsub("([^%w])", "%%%1") .. "/"
  return function(path)
    return M.adjust_sep(path):gsub(pattern, "", 1)
  end
end

M.to_relative = function(path, base_path)
  return M.relative_modifier(base_path)(path)
end

M.parse_with_row = function(line)
  local path, row = line:match("(.*):(%d+):")
  if not path then
    return
  end
  local matched_line = line:sub(#path + #row + #(":") * 2 + 1)
  return path, tonumber(row), matched_line
end

M.add_trailing_slash = function(path)
  if vim.endswith(path, "/") then
    return path
  end
  return path .. "/"
end

M.join = function(...)
  local items = {}
  for _, item in ipairs({...}) do
    if vim.endswith(item, "/") then
      item = item:sub(1, #item - 1)
    end
    table.insert(items, item)
  end
  return table.concat(items, "/")
end

if vim.fn.has("win32") == 1 then
  M.adjust_sep = function(path)
    return path:gsub("\\", "/")
  end

  M.home = function()
    return os.getenv("USERPROFILE")
  end

  M.env_separator = ";"
else
  M.adjust_sep = function(path)
    return path
  end

  M.home = function()
    return os.getenv("HOME")
  end

  M.env_separator = ":"
end

-- for app

M.user_data_path = function(file_name)
  return vim.fn.stdpath("data") .. "/kivi.nvim/" .. file_name
end

return M