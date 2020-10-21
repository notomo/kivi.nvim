local listlib = require("kivi/lib/list")
local windowlib = require("kivi/lib/window")
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
  local bufnr = vim.api.nvim_create_buf(false, true)
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

  local tbl = {bufnr = bufnr, _window_id = window_id}
  return setmetatable(tbl, PendingUI), key
end

M.from_current = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local window_id = vim.api.nvim_get_current_win()
  local tbl = {bufnr = bufnr, _window_id = window_id}
  return setmetatable(tbl, PendingUI)
end

M._close = function(self)
  return windowlib.close(self._window_id)
end

M._redraw = function(self, bufnr, collect_result, opts)
  local tbl = {
    _kind_name = collect_result.source.kind_name,
    _selected = {},
    _window_id = self._window_id,
  }
  local root, ok = collect_result:get()
  if ok then
    tbl._nodes = root:all()
    M._set_lines(bufnr, tbl._nodes, collect_result.source, opts.before_path)
    -- TODO: else job
  end

  return setmetatable(tbl, RenderedUI)
end

PendingUI.close = M._close
RenderedUI.close = M._close
PendingUI.redraw = M._redraw
RenderedUI.redraw = M._redraw

M._set_lines = function(bufnr, nodes, source, before_path)
  local lines = vim.tbl_map(function(node)
    return node.value
  end, nodes)
  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable = false

  source:highlight(bufnr, nodes)

  if before_path ~= nil then
    for i, node in ipairs(nodes) do
      if node.path == before_path then
        vim.api.nvim_win_set_cursor(0, {i, 0})
        break
      end
    end
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
