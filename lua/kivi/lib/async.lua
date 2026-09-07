local M = {}

--- Run the functions concurrently and wait for all of them.
--- Raises the first error like Promise.all().
--- @async
--- @param fs (async fun())[]
function M.all(fs)
  local tasks = vim
    .iter(fs)
    :map(function(f)
      return vim.async.run(f)
    end)
    :totable()
  for _, task in ipairs(tasks) do
    vim.async.await(task)
  end
end

return M
