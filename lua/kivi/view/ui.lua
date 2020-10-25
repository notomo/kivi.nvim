local windowlib = require("kivi/lib/window")
local cursorlib = require("kivi/lib/cursor")
local highlights = require("kivi/lib/highlight")
local layouts = require("kivi/view/layout")
local vim = vim

local M = {}

local PendingUI = {}
PendingUI.__index = PendingUI

local RenderedUI = {}
RenderedUI.__index = RenderedUI

M._to_filetype = function(source_name)
  return ("kivi-%s"):format(source_name)
end

M.open = function(source_name, layout)
  local bufnr, source_bufnr
  local current_bufnr = vim.api.nvim_get_current_buf()
  local filetype = M._to_filetype(source_name)
  if vim.bo.filetype == filetype then
    bufnr = current_bufnr
  else
    bufnr = vim.api.nvim_create_buf(false, true)
    source_bufnr = current_bufnr
  end
  local key = ("%s/%d"):format(source_name, bufnr)
  vim.api.nvim_buf_set_name(bufnr, "kivi://" .. key .. "/kivi")
  vim.bo[bufnr].filetype = filetype
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].modifiable = false

  local window_id = layouts.open(layout, bufnr)
  vim.wo[window_id].number = false

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

M._redraw = function(self, root, source, history)
  local tbl = {
    bufnr = self.bufnr,
    source = source,
    _selected = {},
    _window_id = self._window_id,
    _nodes = root:all(),
    _selection_hl_factory = highlights.new_factory("kivi-selection-highlight", self.bufnr),
  }

  M._set_lines(tbl.bufnr, tbl._nodes, source, history, root.path)

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
      if node.path == latest_path and i ~= 1 then
        cursorlib.set_row(i)
        ok = true
        break
      end
    end
  end
  if not ok then
    ok = history:restore(current_path)
  end
  if not ok and latest_path ~= current_path then
    cursorlib.set_row(2)
  end
end

function RenderedUI.selected_nodes(self, action_name, range)
  if action_name ~= "toggle_selection" and not vim.tbl_isempty(self._selected) then
    -- TODO sort by index?
    return vim.tbl_values(self._selected)
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

function RenderedUI.toggle_selections(self, nodes)
  for _, node in ipairs(nodes) do
    if self._selected[node.path] then
      self._selected[node.path] = nil
    else
      self._selected[node.path] = node
    end
  end

  local highligher = self._selection_hl_factory:reset()
  highligher:filter("KiviSelected", self._nodes, function(node)
    return self._selected[node.path] ~= nil
  end)
end

function RenderedUI.reset_selections(self, action_name)
  if action_name == "toggle_selection" then
    return
  end
  self._selected = {}
  self._selection_hl_factory:reset()
end

vim.api.nvim_command("highlight default link KiviSelected Statement")

return M
