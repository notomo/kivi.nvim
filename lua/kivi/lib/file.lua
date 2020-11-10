local vim = vim

local M = {}

M.readable = function(file_path)
  return vim.fn.filereadable(file_path) ~= 0
end

M.is_directory = function(path)
  return vim.fn.isdirectory(path) ~= 0
end

M.create_if_need = function(file_path)
  local dir_path = vim.fn.fnamemodify(file_path, ":h")
  if not M.is_directory(dir_path) then
    vim.fn.mkdir(dir_path, "p")
  end
  if M.readable(file_path) then
    return false
  end
  io.open(file_path, "w"):close()
  return true
end

M.read_lines = function(path, s, e)
  local f = io.open(path, "r")
  if f == nil then
    return {}
  end

  local lines = {}
  local read = f:lines()
  for _ = 1, s - 1, 1 do
    read() -- skip
  end
  for _ = s, e, 1 do
    table.insert(lines, read())
  end
  io.close(f)
  return lines
end

M.write_lines = function(path, lines)
  local f = io.open(path, "w")
  for _, line in ipairs(lines) do
    f:write(line .. "\n")
  end
  f:close()
end

M.find_upward_dir = function(child_pattern)
  local found_file = vim.fn.findfile(child_pattern, ".;")
  if found_file ~= "" then
    return vim.fn.fnamemodify(found_file, ":p:h")
  end

  local found_dir = vim.fn.finddir(child_pattern, ".;")
  if found_dir ~= "" then
    return vim.fn.fnamemodify(found_dir, ":p:h:h")
  end

  return nil
end

M.find_git_root = function()
  local git_root = M.find_upward_dir(".git")
  if git_root == nil then
    return nil, "not found .git"
  end
  return git_root, nil
end

M.delete = function(path)
  vim.fn.delete(path, "rf")
end

local get_bufnr = function(path)
  local pattern = ("^%s$"):format(path)
  return vim.fn.bufnr(pattern)
end

M.open = function(path)
  local bufnr = get_bufnr(path)
  if bufnr ~= -1 then
    vim.api.nvim_command("buffer " .. bufnr)
  else
    vim.api.nvim_command("edit " .. path)
  end
end

M.tab_open = function(path)
  local bufnr = get_bufnr(path)
  if bufnr ~= -1 then
    vim.api.nvim_command("tabedit")
    vim.api.nvim_command("buffer " .. bufnr)
  else
    vim.api.nvim_command("tabedit " .. path)
  end
end

M.vsplit_open = function(path)
  local bufnr = get_bufnr(path)
  if bufnr ~= -1 then
    vim.api.nvim_command("vsplit")
    vim.api.nvim_command("buffer " .. bufnr)
  else
    vim.api.nvim_command("vsplit" .. path)
  end
end

M.rename = function(from, to)
  vim.fn.rename(from, to)
end

M.copy = function(from, to)
  local from_file = io.open(from, "r")
  local content = from_file:read("*a")
  from_file:close()

  local to_file = io.open(to, "w")
  to_file:write(content)
  to_file:close()
end

M.exists = function(path)
  return M.readable(path) or M.is_directory(path)
end

return M
