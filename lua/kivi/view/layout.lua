local Layouts = {}

function Layouts.no(bufnr)
  vim.api.nvim_win_set_buf(0, bufnr)
  return true
end

function Layouts.vertical(bufnr, opts)
  vim.cmd.vsplit()
  vim.api.nvim_win_set_width(0, opts.width or 38)
  vim.api.nvim_win_set_buf(0, bufnr)
  return true
end

function Layouts.tab(bufnr)
  vim.cmd.tabedit()
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.api.nvim_win_set_buf(0, bufnr)
  return true
end

function Layouts.hide()
  return false
end

local M = {}

function M.open(bufnr, opts)
  opts = opts or {}
  local typ = opts.type

  local f = Layouts[typ]
  if not f then
    error("unexpected layout type: " .. tostring(typ))
  end

  local opened = f(bufnr, opts)
  if opened then
    vim.api.nvim_set_option_value("number", false, { scope = "local" })
    vim.api.nvim_set_option_value("list", false, { scope = "local" })
  end
  return vim.api.nvim_get_current_win()
end

return M
