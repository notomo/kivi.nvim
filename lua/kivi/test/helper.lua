local helper = require("vusted.helper")
local plugin_name = helper.get_module_root(...)

helper.root = helper.find_plugin_root(plugin_name)
vim.opt.packpath:prepend(vim.fs.joinpath(helper.root, "spec/.shared/packages"))
require("assertlib").register(require("vusted.assert").register)

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
end

function helper.skip_if_win32(pending_fn)
  if vim.fn.has("win32") == 1 then
    pending_fn("skip on win32")
  end
end

function helper.set_inputs(...)
  local answers = vim.fn.reverse({ ... })
  ---@diagnostic disable-next-line: duplicate-set-field
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
  local old = vim.api.nvim_win_get_cursor(0)

  local result = vim.fn.search(pattern)
  if result == 0 then
    local info = debug.getinfo(2)
    local pos = ("%s:%d"):format(info.source, info.currentline)
    local lines = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
    local msg = ("on %s: `%s` not found in buffer:\n%s"):format(pos, pattern, lines)
    assert(false, msg)
  end

  local current = vim.api.nvim_win_get_cursor(0)
  if old[1] ~= current[1] or old[2] ~= current[2] then
    vim.api.nvim_exec_autocmds("CursorMoved", {})
  end
  return result
end

function helper.symlink(from, to)
  vim.uv.fs_symlink(helper.test_data:path(to), helper.test_data:path(from))
end

function helper.path(path)
  return helper.test_data:path(path or "")
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

function helper.wait_pattern(pattern)
  local ok = vim.wait(1000, function()
    return vim.fn.search(pattern, "n") ~= 0
  end)
  if not ok then
    error("wait timeout: does not exist pattern: " .. pattern)
  end
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

asserts.create("current_dir"):register_eq(function()
  return require("kivi.lib.path").normalize(vim.fn.getcwd()):gsub(helper.test_data:path("?"), "")
end)

asserts.create("register_value"):register_eq(function(name)
  return vim.fn.getreg(name)
end)

function helper.typed_assert(assert)
  local x = require("assertlib").typed(assert)
  ---@cast x +{current_dir:fun(want), register_value:fun(name,want)}
  return x
end

return helper
