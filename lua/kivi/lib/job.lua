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

function M.series(elements, promise_factory)
  local promise = require("kivi.vendor.promise").resolve()
  for _, e in ipairs(elements) do
    promise = promise:next(function()
      return promise_factory(e)
    end)
  end
  return promise
end

function M.wait(promise)
  local finished = false
  promise:finally(function()
    finished = true
  end)
  local ok = vim.wait(5000, function()
    return finished
  end, 10, false)
  if not ok then
    error("wait timeout")
  end
end

return M
