local M = {}

--- @async
function M.promise(cmd)
  --- @type vim.SystemCompleted?
  local completed
  vim.async.await(function(callback)
    -- schedule_wrap so the task does not resume in a fast event context
    vim.system(
      cmd,
      { text = true },
      vim.schedule_wrap(function(o)
        completed = o
        callback()
      end)
    )
  end)
  assert(completed)
  if completed.code ~= 0 then
    error(vim.trim(completed.stdout .. completed.stderr), 0)
  end
  return vim.trim(completed.stderr .. completed.stdout)
end

--- @async
function M.series(elements, f)
  for _, e in ipairs(elements) do
    f(e)
  end
end

function M.wait(task)
  local finished = false
  task:on_complete(function()
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
