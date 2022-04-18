local M = {}

function M.open(opts)
  return require("kivi.command").open(opts)
end

function M.navigate(path, source_setup_opts)
  return require("kivi.command").navigate(path, source_setup_opts)
end

function M.execute(action_name, opts, action_opts)
  return require("kivi.command").execute(action_name, opts, action_opts)
end

function M.setup(config)
  return require("kivi.command").setup(config)
end

function M.is_parent()
  return require("kivi.command").is_parent()
end

return M
