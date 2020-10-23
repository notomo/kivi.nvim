local listlib = require("kivi/lib/list")
local windowlib = require("kivi/lib/window")
local cursorlib = require("kivi/lib/cursor")
local vim = vim

local M = {}

local PendingUI = {}
PendingUI.__index = PendingUI

local RenderedUI = {}
RenderedUI.__index = RenderedUI

local layouts = {
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

M.open = function(source_name, layout)
  local bufnr, source_bufnr
  local current_bufnr = vim.api.nvim_get_current_buf()
  if vim.bo.filetype == "kivi" then
    bufnr = current_bufnr
  else
    bufnr = vim.api.nvim_create_buf(false, true)
    source_bufnr = current_bufnr
  end
  local key = ("%s/%d"):format(source_name, bufnr)
  vim.api.nvim_buf_set_name(bufnr, "kivi://" .. key .. "/kivi")
  vim.bo[bufnr].filetype = "kivi"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].modifiable = false

  local window = 0
  layouts[layout](bufnr)
  vim.api.nvim_win_set_width(window, 38)
  vim.wo[window].number = false
  local window_id = vim.api.nvim_get_current_win()

  local tbl = {bufnr = bufnr, source_bufnr = source_bufnr, _window_id = window_id}
  return setmetatable(tbl, PendingUI), key
end

M.from_current = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local window_id = vim.api.nvim_get_current_win()
  local tbl = {bufnr = bufnr, source_bufnr = nil, _window_id = window_id}
  return setmetatable(tbl, PendingUI)
end

M._close = function(self)
  return windowlib.close(self._window_id)
end

M._redraw = function(self, bufnr, root, source, history)
  local tbl = {
    _kind_name = source.kind_name,
    _selected = {},
    _window_id = self._window_id,
    _nodes = root:all(),
  }

  M._set_lines(bufnr, tbl._nodes, source, history, root.path)

  return setmetatable(tbl, RenderedUI)
end

PendingUI.close = M._close
RenderedUI.close = M._close
PendingUI.redraw = M._redraw
RenderedUI.redraw = M._redraw

M._set_lines = function(bufnr, nodes, source, history, current_path)
  local lines = vim.tbl_map(function(node)
    return node.value
  end, nodes)
  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable = false

  source:highlight(bufnr, nodes)

  local latest_path = source:init_path() or history.latest_path
  local ok = false
  if latest_path ~= nil then
    for i, node in ipairs(nodes) do
      if node.path == latest_path then
        cursorlib.set_row(i)
        ok = true
        break
      end
    end
  end
  if not ok then
    ok = history:restore(current_path)
  end
  if not ok then
    cursorlib.set_row(2)
  end
end

function RenderedUI.node_groups(self, action_name, range)
  local nodes = self:_selected_nodes(action_name, range)
  local node_groups = listlib.group_by(nodes, function(node)
    return node.kind_name or self._kind_name
  end)
  if #node_groups == 0 then
    table.insert(node_groups, {"base", {}})
  end
  return node_groups
end

function RenderedUI._selected_nodes(self, action_name, range)
  -- TODO: select action
  if action_name ~= "toggle_selection" and not vim.tbl_isempty(self._selected) then
    local selected = vim.tbl_values(self._selected)
    table.sort(selected, function(a, b)
      return a.index < b.index
    end)
    return selected
  end

  if range ~= nil then
    local nodes = {}
    for i = range.first, range.last, 1 do
      table.insert(nodes, self._nodes[i])
    end
    return nodes
  end

  return {self._nodes[vim.fn.line(".")]}
end

return M
