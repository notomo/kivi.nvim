local pathlib = require("kivi.lib.path")
local vim = vim
local uv = vim.uv

local M = {}

function M.is_dir(path)
  local stat = uv.fs_stat(path)
  return stat and stat.type == "directory"
end

function M.is_link(path)
  local stat = uv.fs_stat(path)
  return stat and stat.type == "link"
end

M.home_dir = uv.os_homedir()

function M.adjust(path)
  path = path or uv.cwd()

  if vim.startswith(path, "~") then
    path = path:gsub("^~", M.home_dir)
  end

  local real_path = uv.fs_realpath(path)
  if real_path then
    path = real_path
  end

  path = pathlib.normalize(path)
  if M.is_dir(path) and not vim.endswith(path, "/") then
    path = path .. "/"
  end
  return path
end

function M._link_entry(path)
  local real_path = uv.fs_realpath(path)
  if real_path then
    return path, real_path, M.is_dir(real_path), false
  end
  return path, nil, false, true
end

function M.entries(dir)
  local fs = uv.fs_scandir(dir)
  if not fs then
    return "can't open " .. dir
  end

  local entries = {}
  while true do
    local file_name, type = uv.fs_scandir_next(fs)
    if not file_name then
      break
    end

    local path, real_path, is_directory, is_broken_link
    local joined = pathlib.join(dir, file_name)
    if type == "link" then
      path, real_path, is_directory, is_broken_link = M._link_entry(joined)
    else
      path = M.adjust(joined)
      is_directory = type == "directory"
      is_broken_link = false
    end

    local name = file_name
    if is_directory then
      name = name .. "/"
    end
    table.insert(entries, {
      path = path,
      real_path = real_path,
      is_directory = is_directory,
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
  local promise, resolve, reject = require("kivi.vendor.promise").with_resolvers()

  local sender
  sender = vim.uv.new_async(vim.schedule_wrap(function(err)
    if err then
      reject(err)
    else
      resolve()
    end
    assert(sender)
    sender:close()
  end))
  assert(sender)

  ---@diagnostic disable-next-line: param-type-mismatch
  vim.uv.new_thread(function(async, _path)
    local ok, result = pcall(function()
      require("vim.fs").rm(_path, { recursive = true })
    end)
    if ok then
      async:send()
    else
      async:send(result)
    end
    ---@diagnostic disable-next-line: param-type-mismatch
  end, sender, path)

  return promise
end

function M.rename(from, to)
  local promise, resolve, reject = require("kivi.vendor.promise").with_resolvers()
  uv.fs_rename(from, to, function(err, ok)
    assert(not err, err)
    if ok then
      resolve()
      return
    end
    reject()
  end)
  return promise
end

local _copy_dir
if vim.uv.os_uname().version:match("Windows") then
  _copy_dir = function(from, to)
    local from_path = pathlib.trim_slash(from):gsub("/", "\\")
    local to_path = pathlib.trim_slash(to):gsub("/", "\\")
    local cmd = { "xcopy", "/Y", "/E", "/I", from_path, to_path }
    return require("kivi.lib.job").promise(cmd)
  end
else
  _copy_dir = function(from, to)
    if M.is_dir(to) then
      return require("kivi.lib.job").promise({
        "cp",
        "-RT",
        from,
        pathlib.trim_slash(to),
      })
    end
    return require("kivi.lib.job").promise({
      "cp",
      "-R",
      from,
      pathlib.trim_slash(to),
    })
  end
end
M._copy_dir = _copy_dir

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

  return require("kivi.vendor.promise").resolve()
end

function M._bufnr(path)
  local pattern = ("^%s$"):format(path)
  local bufnr = vim.fn.bufnr(pattern)
  if bufnr ~= -1 then
    return bufnr
  end
  return nil
end


function M.open(path)
  local bufnr = M._bufnr(path)
  if bufnr ~= nil then
    vim.cmd.buffer(bufnr)
  else
    vim.cmd.edit({ args = { path }, magic = { file = false } })
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
    vim.cmd.tabedit({ args = { path }, magic = { file = false } })
  end
end

function M.vsplit_open(path)
  local bufnr = M._bufnr(path)
  if bufnr ~= nil then
    vim.cmd.vsplit()
    vim.cmd.buffer(bufnr)
  else
    vim.cmd.vsplit({ args = { path }, magic = { file = false } })
  end
end

function M.readable(path)
  return vim.uv.fs_access(path, "R")
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

function M.details(paths)
  local cmd = { "ls", "-lh", unpack(paths) }
  return require("kivi.lib.job").promise(cmd)
end

return M
