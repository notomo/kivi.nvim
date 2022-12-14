local pathlib = require("kivi.lib.path")
local vim = vim
local loop = vim.loop

local M = {}

function M.is_dir(path)
  local stat = loop.fs_stat(path)
  return stat and stat.type == "directory"
end

function M.is_link(path)
  local stat = loop.fs_stat(path)
  return stat and stat.type == "link"
end

M.home_dir = loop.os_homedir()

function M.adjust(path)
  path = path or loop.cwd()

  if vim.startswith(path, "~") then
    path = path:gsub("^~", M.home_dir)
  end

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

function M._link_entry(path)
  local real_path = loop.fs_realpath(path)
  if real_path then
    return path, real_path, M.is_dir(real_path), false
  end
  return path, nil, false, true
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

    local path, real_path, is_directory, is_link, is_broken_link
    local joined = pathlib.join(dir, file_name)
    if type == "link" then
      path, real_path, is_directory, is_broken_link = M._link_entry(joined)
      is_link = true
    else
      path = M.adjust(joined)
      is_directory = type == "directory"
      is_broken_link = false
      is_link = false
    end

    local name = file_name
    if is_directory then
      name = name .. "/"
    end
    table.insert(entries, {
      path = path,
      real_path = real_path,
      is_directory = is_directory,
      is_link = is_link,
      is_broken_link = is_broken_link,
      name = name,
    })
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
  if M.is_link(path) then
    return vim.fn.delete(pathlib.trim_slash(path))
  end
  return vim.fn.delete(path, "rf")
end

function M.rename(from, to)
  return loop.fs_rename(from, to)
end

if vim.loop.os_uname().version:match("Windows") then
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
  if not from_file then
    error("cannot open to read: " .. from)
  end
  local content = from_file:read("*a")
  from_file:close()

  local to_file = io.open(to, "w")
  if not to_file then
    error("cannot open to write: " .. to)
  end
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
  vim.cmd.lcd({ args = { M._escape(path) }, mods = { silent = true } })
end

function M.open(path)
  local bufnr = M._bufnr(path)
  if bufnr ~= nil then
    vim.cmd.buffer(bufnr)
  else
    vim.cmd.edit(M._escape(path))
  end
end

function M.tab_open(path)
  local bufnr = M._bufnr(path)
  if bufnr ~= nil then
    vim.cmd.tabedit()
    vim.bo.buftype = "nofile"
    vim.bo.bufhidden = "wipe"
    vim.cmd.buffer(bufnr)
  else
    vim.cmd.tabedit(M._escape(path))
  end
end

function M.vsplit_open(path)
  local bufnr = M._bufnr(path)
  if bufnr ~= nil then
    vim.cmd.vsplit()
    vim.cmd.buffer(bufnr)
  else
    vim.cmd.vsplit(M._escape(path))
  end
end

function M.readable(path)
  return vim.loop.fs_access(path, "R")
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
    return pathlib.parent(M.adjust(found_file))
  end

  local found_dir = vim.fn.finddir(child_pattern, ".;")
  if found_dir ~= "" then
    return pathlib.parent(M.adjust(found_dir))
  end

  return nil
end

function M.find_git_root()
  local git_root = M.find_upward_dir(".git")
  if git_root == nil then
    return nil, "not found .git"
  end
  return git_root, nil
end

function M.details(paths)
  local cmd = { "ls", "-lh", unpack(paths) }
  return require("kivi.lib.job").promise(cmd)
end

return M
