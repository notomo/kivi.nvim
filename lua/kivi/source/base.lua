local M = {}

function M.collect()
  return {}
end

function M.highlight()
end

function M.init_path()
end

function M.hook()
end

function M.setup(_, opts)
  return opts
end

M.opts = {}
M.setup_opts = {}
M.kind_name = "base"

return M
