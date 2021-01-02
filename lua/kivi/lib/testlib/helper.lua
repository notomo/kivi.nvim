local M = {}

local root, find_err = require("kivi/lib/path").find_root("kivi/*.lua")
if find_err ~= nil then
  error(find_err)
end
M.root = root
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
  M.set_inputs()
end

M.after_each = function()
  M.command("tabedit")
  M.command("tabonly!")
  M.command("silent! %bwipeout!")
  M.command("filetype off")
  M.command("syntax off")
  M.command("messages clear")
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

M.set_inputs = function(...)
  local answers = vim.fn.reverse({...})
  require("kivi/lib/input").read = function(msg)
    local answer = table.remove(answers)
    if answer == nil then
      print(msg)
      assert("no input")
    end
    print(msg .. answer)
    return answer
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

asserts.create("current_dir"):register_eq(function()
  return require("kivi/lib/path").adjust_sep(vim.fn.getcwd()):gsub(M.test_data_dir .. "?", "")
end)

asserts.create("register_value"):register_eq(function(name)
  return vim.fn.getreg(name)
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

asserts.create("error_message"):register(function(self)
  return function(_, args)
    local expected = args[1]
    local f = args[2]
    local ok, actual = pcall(f)
    if ok then
      self:set_positive("should be error")
      self:set_negative("should be error")
      return false
    end
    self:set_positive(("error message should end with '%s', but actual: '%s'"):format(expected, actual))
    self:set_negative(("error message should not end with '%s', but actual: '%s'"):format(expected, actual))
    return vim.endswith(actual, expected)
  end
end)

asserts.create("exists_message"):register(function(self)
  return function(_, args)
    local expected = args[1]
    self:set_positive(("`%s` not found message"):format(expected))
    self:set_negative(("`%s` found message"):format(expected))
    local messages = vim.split(vim.api.nvim_exec("messages", true), "\n")
    for _, msg in ipairs(messages) do
      if msg:match(expected) then
        return true
      end
    end
    return false
  end
end)

return M
