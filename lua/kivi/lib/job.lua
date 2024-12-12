local M = {}

function M.promise(cmd)
  local promise, resolve, reject = require("kivi.vendor.promise").with_resolvers()

  local ok, err = pcall(function()
    vim.system(cmd, {
      stdout = function(_, data)
        if not data then
          return
        end
        vim.schedule(function()
          resolve(data)
        end)
      end,
      stderr = function(_, data)
        if not data then
          return
        end
        vim.schedule(function()
          reject(data)
        end)
      end,
    })
  end)
  if not ok and err then
    reject(err)
  end

  return promise
end

return M
