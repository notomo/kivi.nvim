local M = {}

function M.promise(cmd)
  local stdout = require("kivi.vendor.misclib.job.output").new()
  local stderr = require("kivi.vendor.misclib.job.output").new()
  return require("kivi.vendor.promise").new(function(resolve, reject)
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
      return reject(err)
    end
  end)
end

return M
