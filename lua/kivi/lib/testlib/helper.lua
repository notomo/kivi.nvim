local plugin_name = vim.split((...):gsub("%.", "/"), "/", true)[1]
local helper = require("vusted.helper")

helper.root = helper.find_plugin_root(plugin_name)

function helper.before_each()
  require("kivi").promise()
  vim.g.clipboard = nil

  helper.test_data = require("kivi.vendor.misclib.test.data_dir").setup(helper.root)
  helper.test_data:cd("")

  helper.set_inputs()
end

function helper.after_each()
  helper.test_data:teardown()
  helper.cleanup()
  helper.cleanup_loaded_modules(plugin_name)
  print(" ")
end

function helper.skip_if_win32(pending_fn)
  if vim.fn.has("win32") == 1 then
    pending_fn("skip on win32")
  end
end

function helper.buffer_log()
  local lines = vim.fn.getbufline("%", 1, "$")
  for _, line in ipairs(lines) do
    print(line)
  end
end

function helper.set_inputs(...)
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

function helper.set_lines(lines)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(lines, "\n"))
end

function helper.search(pattern)
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

function helper.symlink(from, to)
  vim.loop.fs_symlink(helper.test_data.full_path .. to, helper.test_data.full_path .. from)
end

function helper.path(path)
  return helper.test_data.full_path .. (path or "")
end

function helper.on_finished()
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

function helper.wait(promise)
  local on_finished = helper.on_finished()
  promise:finally(function()
    on_finished()
  end)
  on_finished:wait()
end

function helper.clipboard()
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

local asserts = require("vusted.assert").asserts
local asserters = require(plugin_name .. ".vendor.assertlib").list()
require(plugin_name .. ".vendor.misclib.test.assert").register(asserts.create, asserters)

asserts.create("file_name"):register_eq(function()
  return vim.fn.fnamemodify(vim.fn.bufname("%"), ":t")
end)

asserts.create("current_dir"):register_eq(function()
  return require("kivi.lib.path").adjust_sep(vim.fn.getcwd()):gsub(helper.test_data.full_path .. "?", "")
end)

asserts.create("register_value"):register_eq(function(name)
  return vim.fn.getreg(name)
end)

return helper
