local pathlib = require("kivi.lib.path")
local vim = vim

local M = {}

local File = setmetatable({}, pathlib.Path)
File.__index = File
M.File = File

function File.new(path)
  if type(path) == "table" then
    path = path:get()
  end
  local tbl = { path = pathlib.adjust_sep(vim.fn.fnamemodify(path, ":p")) }
  return setmetatable(tbl, File)
end

function File.__tostring(self)
  return self.path
end

function File.is_dir(self)
  return vim.fn.isdirectory(self.path) ~= 0
end

function File.can_read(self)
  return vim.loop.fs_access(self.path, "r")
end

function File.paths(self)
  if not self:can_read() then
    return nil, "can't open " .. self.path
  end

  local paths = {}
  for _, p in ipairs(vim.fn.readdir(self.path)) do
    table.insert(paths, self:join(p))
  end
  return paths, nil
end

function File.delete(self)
  return vim.fn.delete(self.path, "rf")
end

function File.rename(self, to)
  return vim.fn.rename(self.path, to:get())
end

if vim.fn.has("win32") == 1 then
  function File._copy_dir(self, to)
    local from_path = self:trim_slash():get():gsub("/", "\\")
    local to_path = to:trim_slash():get():gsub("/", "\\")
    local cmd = { "xcopy", "/Y", "/E", "/I", from_path, to_path }
    vim.fn.systemlist(cmd)
  end
else
  function File._copy_dir(self, to)
    if to:is_dir() then
      vim.fn.system({ "cp", "-RT", self.path, to:trim_slash():get() })
    else
      vim.fn.system({ "cp", "-R", self.path, to:trim_slash():get() })
    end
  end
end

function File.copy(self, to)
  if self:is_dir() then
    return self:_copy_dir(to)
  end

  local from_file = io.open(self.path, "r")
  local content = from_file:read("*a")
  from_file:close()

  local to_file = io.open(to:get(), "w")
  to_file:write(content)
  to_file:close()
end

function File._bufnr(self)
  local pattern = ("^%s$"):format(self.path)
  local bufnr = vim.fn.bufnr(pattern)
  if bufnr ~= -1 then
    return bufnr
  end
  return nil
end

function File._escaped_path(self)
  return ([[`='%s'`]]):format(self.path:gsub("'", "''"))
end

function File.lcd(self)
  vim.cmd("silent lcd " .. self:_escaped_path())
end

function File.open(self)
  local bufnr = self:_bufnr()
  if bufnr ~= nil then
    vim.cmd("buffer " .. bufnr)
  else
    vim.cmd("edit " .. self:_escaped_path())
  end
end

function File.tab_open(self)
  local bufnr = self:_bufnr()
  if bufnr ~= nil then
    vim.cmd("tabedit")
    vim.cmd("buffer " .. bufnr)
  else
    vim.cmd("tabedit " .. self:_escaped_path())
  end
end

function File.vsplit_open(self)
  local bufnr = self:_bufnr()
  if bufnr ~= nil then
    vim.cmd("vsplit")
    vim.cmd("buffer " .. bufnr)
  else
    vim.cmd("vsplit " .. self:_escaped_path())
  end
end

function File.readable(self)
  return vim.fn.filereadable(self.path) ~= 0
end

function File.exists(self)
  return self:readable() or self:is_dir()
end

function File.create(self)
  if vim.endswith(self.path, "/") then
    vim.fn.mkdir(self.path, "p")
    return
  end
  local parent = self:parent()
  if not parent:exists() then
    parent:slash():create()
  elseif not parent:is_dir() then
    return ("can't create: %s (%s is a directory)"):format(self.path, parent)
  end
  io.open(self.path, "w"):close()
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
