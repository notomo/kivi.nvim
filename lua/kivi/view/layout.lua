local M = {}

local funcs = {
  vertical = function(bufnr)
    vim.api.nvim_command("vsplit")
    vim.api.nvim_command("buffer " .. bufnr)
  end,
  no = function(bufnr)
    vim.api.nvim_command("buffer " .. bufnr)
  end,
  tab = function(bufnr)
    vim.api.nvim_command("tabedit")
    vim.api.nvim_command("buffer " .. bufnr)
  end,
}

M.open = function(layout, bufnr)
  vim.validate({layout = {layout, "string"}, bufnr = {bufnr, "number"}})
  local f = funcs[layout]
  f(bufnr)
  return vim.api.nvim_get_current_win()
end

return M
