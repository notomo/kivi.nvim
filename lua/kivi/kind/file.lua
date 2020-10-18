local M = {}
M.__index = M

local adjust_cursor = function(item)
  if item.row == nil then
    return
  end
  local count = vim.api.nvim_buf_line_count(0)
  local row = item.row
  if item.row > count then
    row = count
  end
  local range = item.range or {s = {column = 0}}
  vim.api.nvim_win_set_cursor(0, {row, range.s.column})
end

local adjust_window = function()
  vim.api.nvim_command("wincmd w")
end

local get_bufnr = function(item)
  local pattern = ("^%s$"):format(item.path)
  return vim.fn.bufnr(pattern)
end

M.action_open = function(_, items)
  adjust_window()
  for _, item in ipairs(items) do
    local bufnr = get_bufnr(item)
    if bufnr ~= -1 then
      vim.api.nvim_command("buffer " .. bufnr)
    else
      vim.api.nvim_command("edit " .. item.path)
    end
    adjust_cursor(item)
  end
end

M.action_child = function(self, items)
  return self:action_open(items)
end

M.action_parent = function(self, items)
  for _, item in ipairs(items) do
    local path = vim.fn.fnamemodify(item.path, ":h")
    self:open_path("file", {path = path, layout = "no"})
  end
end

M.action_tab_open = function(_, items)
  for _, item in ipairs(items) do
    local bufnr = get_bufnr(item)
    if bufnr ~= -1 then
      vim.api.nvim_command("tabedit")
      vim.api.nvim_command("buffer " .. bufnr)
    else
      vim.api.nvim_command("tabedit " .. item.path)
    end
    adjust_cursor(item)
  end
end

M.action_vsplit_open = function(_, items)
  adjust_window()
  for _, item in ipairs(items) do
    local bufnr = get_bufnr(item)
    if bufnr ~= -1 then
      vim.api.nvim_command("vsplit")
      vim.api.nvim_command("buffer " .. bufnr)
    else
      vim.api.nvim_command("vsplit" .. item.path)
    end
    adjust_cursor(item)
  end
end

M.default_action = "open"

return M
