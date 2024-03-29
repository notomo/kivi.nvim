local Layouts = {}

function Layouts.no(bufnr)
  vim.api.nvim_win_set_buf(0, bufnr)
  return true
end

function Layouts.vertical(width)
  vim.validate({ width = { width, "number", true } })
  width = width or 38
  return function(bufnr)
    vim.cmd.vsplit()
    vim.api.nvim_win_set_width(0, width)
    vim.api.nvim_win_set_buf(0, bufnr)
    return true
  end
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

local Layout = {}
Layout.__index = Layout

function Layout.new(opts)
  opts = opts or {}
  local typ = opts.type

  local f
  if typ == "vertical" then
    f = Layouts.vertical(opts.width)
  elseif typ == "tab" then
    f = Layouts.tab
  elseif typ == "no" then
    f = Layouts.no
  elseif typ == "hide" then
    f = Layouts.hide
  else
    error("unexpected layout type: " .. tostring(typ))
  end

  local tbl = { _f = f }
  return setmetatable(tbl, Layout)
end

function Layout.open(self, bufnr)
  vim.validate({ bufnr = { bufnr, "number" } })
  local opened = self._f(bufnr)
  if opened then
    vim.api.nvim_set_option_value("number", false, { scope = "local" })
    vim.api.nvim_set_option_value("list", false, { scope = "local" })
  end
  return vim.api.nvim_get_current_win()
end

return Layout
