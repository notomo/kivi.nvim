local M = {}

function M.promise(cmd)
  local promise, resolve, reject = require("kivi.vendor.promise").with_resolvers()

  local ok, err = pcall(function()
    vim.system(
      cmd,
      {
        text = true,
      },
      vim.schedule_wrap(function(o)
        if o.code == 0 then
          return resolve(vim.trim(o.stderr .. o.stdout))
        end
        return reject(vim.trim(o.stdout .. o.stderr))
      end)
    )
  end)
  if not ok and err then
    reject(err)
  end

  return promise
end

return M
