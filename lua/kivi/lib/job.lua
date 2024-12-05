local M = {}

function M.promise(cmd)
  local stdout = require("kivi.vendor.misclib.job.output").new()
  local stderr = require("kivi.vendor.misclib.job.output").new()

  local promise, resolve, reject = require("kivi.vendor.promise").with_resolvers()

  local _, err = require("kivi.vendor.misclib.job").start(cmd, {
    on_exit = function(_, code)
      if code ~= 0 then
        local err = stderr:str()
        return reject(err)
      end
      local str = table.concat(stdout:lines(), "\n")
      return resolve(str)
    end,
    on_stdout = stdout:collector(),
    on_stderr = stderr:collector(),
    stderr_buffered = true,
    stdout_buffered = true,
  })
  if err then
    reject(err)
  end

  return promise
end

function M.start(cmd)
  local cmd_name = table.concat(cmd, " ")
  local prefix = ("[%s]: "):format(cmd_name)

  local promise, resolve, reject = require("kivi.vendor.promise").with_resolvers()

  local _, err = require("kivi.vendor.misclib.job").start(cmd, {
    on_exit = function(_, code)
      vim.api.nvim_echo({ { prefix .. ("exit: %d"):format(code) } }, true, {})
      if code ~= 0 then
        return reject()
      end
      return resolve()
    end,
    on_stdout = function(_, data, _)
      data = vim
        .iter(data)
        :filter(function(v)
          return v ~= ""
        end)
        :totable()
      for _, msg in ipairs(data) do
        vim.api.nvim_echo({ { prefix .. msg } }, true, {})
      end
    end,
    on_stderr = function(_, data, _)
      data = vim
        .iter(data)
        :filter(function(v)
          return v ~= ""
        end)
        :totable()
      for _, msg in ipairs(data) do
        vim.api.nvim_echo({ { prefix .. msg, "WarningMsg" } }, true, {})
      end
    end,
    stderr_buffered = true,
    stdout_buffered = true,
  })
  if err then
    reject(err)
  end

  return promise
end

return M
