local plugin_name = vim.split((...):gsub("%.", "/"), "/", true)[1]
local M = require("vusted.helper")

M.root = M.find_plugin_root(plugin_name)

function M.before_each()
  require("kivi").promise()
  vim.g.clipboard = nil
  vim.cmd("filetype on")
  vim.cmd("syntax enable")
  M.test_data_path = "spec/test_data/" .. math.random(1, 2 ^ 30) .. "/"
  M.test_data_dir = M.root .. "/" .. M.test_data_path
  M.new_directory("")
  vim.api.nvim_set_current_dir(M.test_data_dir)
  M.set_inputs()
end

function M.after_each()
  vim.cmd("tabedit")
  vim.cmd("tabonly!")
  vim.cmd("silent! %bwipeout!")
  vim.cmd("filetype off")
  vim.cmd("syntax off")
  vim.cmd("messages clear")
  print(" ")

  M.cleanup_loaded_modules(plugin_name)
  vim.fn.delete(M.root .. "/spec/test_data", "rf")
end

function M.skip_if_win32(pending_fn)
  if vim.fn.has("win32") == 1 then
    pending_fn("skip on win32")
  end
end

function M.buffer_log()
  local lines = vim.fn.getbufline("%", 1, "$")
  for _, line in ipairs(lines) do
    print(line)
  end
end

function M.set_inputs(...)
  local answers = vim.fn.reverse({ ... })
  require("kivi.lib.input").read = function(msg)
    local answer = table.remove(answers)
    if answer == nil then
      print(msg)
      assert("no input")
    end
    print(msg .. answer)
    return answer
  end
end

function M.set_lines(lines)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(lines, "\n"))
end

function M.search(pattern)
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

function M.new_file(path, ...)
  local f = io.open(M.test_data_dir .. path, "w")
  for _, line in ipairs({ ... }) do
    f:write(line .. "\n")
  end
  f:close()
end

function M.new_directory(path)
  vim.fn.mkdir(M.test_data_dir .. path, "p")
end

function M.delete(path)
  vim.fn.delete(M.test_data_dir .. path, "rf")
end

function M.cd(path)
  vim.api.nvim_set_current_dir(M.test_data_dir .. path)
end

function M.path(path)
  return M.test_data_dir .. (path or "")
end

function M.on_finished()
  local finished = false
  return setmetatable({
    wait = function()
      local ok = vim.wait(1000, function()
        return finished
      end, 10, false)
      if not ok then
        error("wait timeout")
      end
    end,
  }, {
    __call = function()
      finished = true
    end,
  })
end

function M.wait(promise)
  local on_finished = M.on_finished()
  promise:finally(function()
    on_finished()
  end)
  on_finished:wait()
end

function M.clipboard()
  local register = {}
  return {
    name = "test",
    copy = {
      ["+"] = function(lines, regtype)
        vim.list_extend(register, { lines, regtype })
      end,
    },
    paste = {
      ["+"] = function()
        return register
      end,
    },
  }
end

function M.window_count()
  return vim.fn.tabpagewinnr(vim.fn.tabpagenr(), "$")
end

local asserts = require("vusted.assert").asserts

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
  return require("kivi.lib.path").adjust_sep(vim.fn.getcwd()):gsub(M.test_data_dir .. "?", "")
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
