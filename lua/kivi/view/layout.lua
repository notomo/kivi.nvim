local M = {}

local funcs = {
  vertical = function(bufnr)
    vim.cmd("vsplit")
    vim.cmd("buffer " .. bufnr)
    vim.api.nvim_win_set_width(0, 38)
  end,
  no = function(bufnr)
    vim.cmd("buffer " .. bufnr)
  end,
  tab = function(bufnr)
    vim.cmd("tabedit")
    vim.cmd("buffer " .. bufnr)
  end,
}

M.open = function(layout, bufnr)
  vim.validate({layout = {layout, "string"}, bufnr = {bufnr, "number"}})
  local f = funcs[layout]
  f(bufnr)
  return vim.api.nvim_get_current_win()
end

return M
