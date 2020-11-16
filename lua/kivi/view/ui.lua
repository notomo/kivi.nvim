local windowlib = require("kivi/lib/window")
local cursorlib = require("kivi/lib/cursor")
local highlights = require("kivi/lib/highlight")
local layouts = require("kivi/view/layout")
local vim = vim

local M = {}

local PendingUI = {}
PendingUI.__index = PendingUI
M.PendingUI = PendingUI

function PendingUI.open(source, layout)
  local bufnr
  if vim.bo.filetype == source.filetype then
    bufnr = vim.api.nvim_get_current_buf()
  else
    bufnr = vim.api.nvim_create_buf(false, true)
  end

  local key = ("%s/%d"):format(source.name, bufnr)
  vim.api.nvim_buf_set_name(bufnr, "kivi://" .. key .. "/kivi")
  vim.bo[bufnr].filetype = source.filetype
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].modifiable = false

  local window_id = layouts.open(layout, bufnr)
  vim.wo[window_id].number = false

  local tbl = {bufnr = bufnr, _window_id = window_id}
  return setmetatable(tbl, PendingUI), key
end

local RenderedUI = {}
RenderedUI.__index = RenderedUI

M._close = function(self)
  return windowlib.close(self._window_id)
end

M._redraw = function(self, root, source, history, is_expand)
  local lines = {}
  local nodes = {}
  root:walk(function(node, depth)
    local space = ("  "):rep(depth - 1)
    table.insert(lines, space .. node.value)
    table.insert(nodes, node)
  end)

  local tbl = {
    bufnr = self.bufnr,
    _selected = {},
    _window_id = self._window_id,
    _nodes = nodes,
    _selection_hl_factory = highlights.new_factory("kivi-selection-highlight", self.bufnr),
  }

  M._set_lines(tbl._window_id, tbl.bufnr, lines, tbl._nodes, source, history, root.path, is_expand)

  return setmetatable(tbl, RenderedUI)
end

PendingUI.close = M._close
RenderedUI.close = M._close
PendingUI.redraw = M._redraw
RenderedUI.redraw = M._redraw

M._set_lines = function(window_id, bufnr, lines, nodes, source, history, current_path, is_expand)
  local origin_row = vim.api.nvim_win_get_cursor(window_id)[1]

  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable = false

  source:highlight(bufnr, nodes)

  if is_expand then
    cursorlib.set_row(origin_row)
    return
  end

  local latest_path = source:init_path() or history.latest_path
  local ok = false
  if latest_path ~= nil then
    for i, node in ipairs(nodes) do
      if node.path:get() == latest_path and i ~= 1 then
        cursorlib.set_row(i)
        ok = true
        break
      end
    end
  end
  if not ok then
    ok = history:restore(current_path:get())
  end
  if not ok and latest_path ~= current_path:get() then
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
