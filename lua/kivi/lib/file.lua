local pathlib = require("kivi.lib.path")
local vim = vim
local loop = vim.loop

local M = {}

function M.is_dir(path)
  local stat = loop.fs_stat(path)
  return stat and stat.type == "directory"
end

function M.adjust(path)
  path = path or loop.cwd()

  local real_path = loop.fs_realpath(path)
  if real_path then
    path = real_path
  end

  path = pathlib.adjust_sep(path)
  if M.is_dir(path) and not vim.endswith(path, "/") then
    path = path .. "/"
  end
  return path
end

function M.entries(dir)
  local fs = loop.fs_scandir(dir)
  if not fs then
    return nil, "can't open " .. dir
  end

  local entries = {}
  while true do
    local file_name, type = loop.fs_scandir_next(fs)
    if not file_name then
      break
    end

    local path = pathlib.join(dir, file_name)
    local is_directory = type == "directory"
    local name = file_name
    if is_directory then
      name = name .. "/"
    end
    table.insert(entries, { path = M.adjust(path), is_directory = is_directory, name = name })
  end

  table.sort(entries, function(a, b)
    local is_dir_a = a.is_directory and 1 or 0
    local is_dir_b = b.is_directory and 1 or 0
    if is_dir_a ~= is_dir_b then
      return is_dir_a > is_dir_b
    end
    return a.name < b.name
  end)

  return entries
end

function M.delete(path)
  if M.is_dir(path) then
    return loop.fs_rmdir(path)
  end
  return loop.fs_unlink(path)
end

function M.rename(from, to)
  return loop.fs_rename(from, to)
end

if vim.fn.has("win32") == 1 then
  function M._copy_dir(from, to)
    local from_path = pathlib.trim_slash(from):gsub("/", "\\")
    local to_path = pathlib.trim_slash(to):gsub("/", "\\")
    local cmd = { "xcopy", "/Y", "/E", "/I", from_path, to_path }
    vim.fn.systemlist(cmd)
  end
else
  function M._copy_dir(from, to)
    if M.is_dir(to) then
      vim.fn.system({ "cp", "-RT", from, pathlib.trim_slash(to) })
    else
      vim.fn.system({ "cp", "-R", from, pathlib.trim_slash(to) })
    end
  end
end

function M.copy(from, to)
  if M.is_dir(from) then
    return M._copy_dir(from, to)
  end

  local from_file = io.open(from, "r")
  local content = from_file:read("*a")
  from_file:close()

  local to_file = io.open(to, "w")
  to_file:write(content)
  to_file:close()
end

function M._bufnr(path)
  local pattern = ("^%s$"):format(path)
  local bufnr = vim.fn.bufnr(pattern)
  if bufnr ~= -1 then
    return bufnr
  end
  return nil
end

function M._escape(path)
  return ([[`='%s'`]]):format(path:gsub("'", "''"))
end

function M.lcd(path)
  vim.cmd("silent lcd " .. M._escape(path))
end

function M.open(path)
  local bufnr = M._bufnr(path)
  if bufnr ~= nil then
    vim.cmd("buffer " .. bufnr)
  else
    vim.cmd("edit " .. M._escape(path))
  end
end

function M.tab_open(path)
  local bufnr = M._bufnr(path)
  if bufnr ~= nil then
    vim.cmd("tabedit")
    vim.cmd("buffer " .. bufnr)
  else
    vim.cmd("tabedit " .. M._escape(path))
  end
end

function M.vsplit_open(path)
  local bufnr = M._bufnr(path)
  if bufnr ~= nil then
    vim.cmd("vsplit")
    vim.cmd("buffer " .. bufnr)
  else
    vim.cmd("vsplit " .. M._escape(path))
  end
end

function M.readable(path)
  return vim.fn.filereadable(path) ~= 0
end

function M.exists(path)
  return M.readable(path) or M.is_dir(path)
end

function M.create(path)
  if M.is_dir(path) then
    return
  end
  if M.exists(pathlib.trim_slash(path)) then
    return ("can't create: %s"):format(path)
  end

  if vim.endswith(path, "/") then
    vim.fn.mkdir(path, "p")
    return
  end

  local parent = pathlib.parent(path)
  if not M.exists(parent) then
    local err = M.create(pathlib.slash(parent))
    if err then
      return err
    end
  end
  io.open(path, "w"):close()
end

function M.find_upward_dir(child_pattern)
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

return M
