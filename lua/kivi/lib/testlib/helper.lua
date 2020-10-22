local M = {}

local get_root = function(name)
  local suffix = "/lua/%?.lua"
  local target = ("%s%s$"):format(name, suffix)
  for _, path in ipairs(vim.split(package.path, ";")) do
    if path:find(target) then
      return path:sub(1, #path - #suffix + 1)
    end
  end
  error("project root directory not found")
end

M.root = get_root("kivi.nvim")
M.test_data_path = "test/test_data/"
M.test_data_dir = M.root .. "/" .. M.test_data_path

M.command = function(cmd)
  local _, err = pcall(vim.api.nvim_command, cmd)
  if err then
    local info = debug.getinfo(2)
    local pos = ("%s:%d"):format(info.source, info.currentline)
    local msg = ("on %s: failed excmd `%s`\n%s"):format(pos, cmd, err)
    error(msg)
  end
end

M.before_each = function()
  M.command("filetype on")
  M.command("syntax enable")
  M.new_directory("")
  vim.api.nvim_set_current_dir(M.test_data_dir)
end

M.after_each = function()
  -- avoid segmentation fault??
  M.command("tabedit")
  M.command("tabprevious")
  M.command("quit!")

  M.command("tabedit")
  M.command("tabonly!")
  M.command("silent! %bwipeout!")
  M.command("filetype off")
  M.command("syntax off")
  print(" ")

  require("kivi/lib/module").cleanup()
  M.delete("")
end

M.buffer_log = function()
  local lines = vim.fn.getbufline("%", 1, "$")
  for _, line in ipairs(lines) do
    print(line)
  end
end

M.set_lines = function(lines)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(lines, "\n"))
end

M.search = function(pattern)
  local result = vim.fn.search(pattern)
  if result == 0 then
    local info = debug.getinfo(2)
    local pos = ("%s:%d"):format(info.source, info.currentline)
    local lines = table.concat(vim.fn.getbufline("%", 1, "$"), "\n")
    local msg = ("on %s: `%s` not found in buffer:\n%s"):format(pos, pattern, lines)
    assert(false, msg)
  end
  return result
end

M.new_file = function(path, ...)
  local f = io.open(M.test_data_dir .. path, "w")
  for _, line in ipairs({...}) do
    f:write(line .. "\n")
  end
  f:close()
end

M.new_directory = function(path)
  vim.fn.mkdir(M.test_data_dir .. path, "p")
end

M.delete = function(path)
  vim.fn.delete(M.test_data_dir .. path, "rf")
end

M.cd = function(path)
  vim.api.nvim_set_current_dir(M.test_data_dir .. path)
end

M.path = function(path)
  return M.test_data_dir .. (path or "")
end

M.window_count = function()
  return vim.fn.tabpagewinnr(vim.fn.tabpagenr(), "$")
end

local vassert = require("vusted.assert")
local asserts = vassert.asserts
M.assert = vassert.assert

asserts.create("window_count"):register_eq(function()
  return M.window_count()
end)

asserts.create("current_line"):register_eq(function()
  return vim.fn.getline(".")
end)

asserts.create("tab_count"):register_eq(function()
  return vim.fn.tabpagenr("$")
end)

asserts.create("filetype"):register_eq(function()
  return vim.bo.filetype
end)

asserts.create("file_name"):register_eq(function()
  return vim.fn.fnamemodify(vim.fn.bufname("%"), ":t")
end)

asserts.create("exists_pattern"):register(function(self)
  return function(_, args)
    local pattern = args[1]
    local result = vim.fn.search(pattern, "n")
    self:set_positive(("`%s` not found"):format(pattern))
    self:set_negative(("`%s` found"):format(pattern))
    return result ~= 0
  end
end)

return M
