local pathlib = require("kivi/lib/path")
local vim = vim

local M = {}

local File = setmetatable({}, pathlib.Path)
File.__index = File
M.File = File

function File.new(path)
  if type(path) == "table" then
    path = path:get()
  end
  local tbl = {path = vim.fn.fnamemodify(path, ":p")}
  return setmetatable(tbl, File)
end

function File.__tostring(self)
  return self.path
end

function File.is_dir(self)
  return vim.fn.isdirectory(self.path) ~= 0
end

function File.paths(self)
  local paths = {}
  for _, p in ipairs(vim.fn.readdir(self.path)) do
    table.insert(paths, self:join(p))
  end
  return paths
end

function File.delete(self)
  return vim.fn.delete(self.path, "rf")
end

function File.rename(self, to)
  return vim.fn.rename(self.path, to:get())
end

function File.copy(self, to)
  if self:is_dir() then
    if to:is_dir() then
      vim.fn.system({"cp", "-RT", self.path, to:trim_slash():get()})
    else
      vim.fn.system({"cp", "-R", self.path, to:trim_slash():get()})
    end
    return
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

function File.open(self)
  local bufnr = self:_bufnr()
  if bufnr ~= nil then
    vim.api.nvim_command("buffer " .. bufnr)
  else
    vim.api.nvim_command("edit " .. self.path)
  end
end

function File.tab_open(self)
  local bufnr = self:_bufnr()
  if bufnr ~= nil then
    vim.api.nvim_command("tabedit")
    vim.api.nvim_command("buffer " .. bufnr)
  else
    vim.api.nvim_command("tabedit " .. self.path)
  end
end

function File.vsplit_open(self)
  local bufnr = self:_bufnr()
  if bufnr ~= nil then
    vim.api.nvim_command("vsplit")
    vim.api.nvim_command("buffer " .. bufnr)
  else
    vim.api.nvim_command("vsplit" .. self.path)
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
  io.open(self.path, "w"):close()
end

return M
