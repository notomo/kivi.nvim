local M = {}
M.__index = M

local adjust_cursor = function(node)
  if node.row == nil then
    return
  end
  local count = vim.api.nvim_buf_line_count(0)
  local row = node.row
  if node.row > count then
    row = count
  end
  local range = node.range or {s = {column = 0}}
  vim.api.nvim_win_set_cursor(0, {row, range.s.column})
end

local adjust_window = function()
  vim.api.nvim_command("wincmd w")
end

local get_bufnr = function(node)
  local pattern = ("^%s$"):format(node.path)
  return vim.fn.bufnr(pattern)
end

M.action_open = function(_, nodes)
  adjust_window()
  for _, node in ipairs(nodes) do
    local bufnr = get_bufnr(node)
    if bufnr ~= -1 then
      vim.api.nvim_command("buffer " .. bufnr)
    else
      vim.api.nvim_command("edit " .. node.path)
    end
    adjust_cursor(node)
  end
end

M.action_child = M.action_open

M.action_parent = function(self, nodes)
  local node = nodes[1]
  if node == nil then
    return
  end
  local root = node:root()
  self:open_path("file", {path = vim.fn.fnamemodify(root.path, ":h"), layout = "no"})
end

M.action_tab_open = function(_, nodes)
  for _, node in ipairs(nodes) do
    local bufnr = get_bufnr(node)
    if bufnr ~= -1 then
      vim.api.nvim_command("tabedit")
      vim.api.nvim_command("buffer " .. bufnr)
    else
      vim.api.nvim_command("tabedit " .. node.path)
    end
    adjust_cursor(node)
  end
end

M.action_vsplit_open = function(_, nodes)
  adjust_window()
  for _, node in ipairs(nodes) do
    local bufnr = get_bufnr(node)
    if bufnr ~= -1 then
      vim.api.nvim_command("vsplit")
      vim.api.nvim_command("buffer " .. bufnr)
    else
      vim.api.nvim_command("vsplit" .. node.path)
    end
    adjust_cursor(node)
  end
end

M.default_action = "open"

return M
