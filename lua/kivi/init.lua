local M = {}

function M.open(opts)
  return require("kivi.command").open(opts)
end

function M.navigate(path)
  return require("kivi.command").navigate(path)
end

function M.execute(action_name, opts, action_opts)
  return require("kivi.command").execute(action_name, opts, action_opts)
end

function M.is_parent()
  return require("kivi.command").is_parent()
end

function M.get()
  return require("kivi.command").get()
end

-- for test
function M.promise()
  return require("kivi.command").promise()
end

return M
