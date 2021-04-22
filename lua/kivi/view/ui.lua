local windowlib = require("kivi.lib.window")
local cursorlib = require("kivi.lib.cursor")
local highlights = require("kivi.lib.highlight")
local layouts = require("kivi.view.layout")
local vim = vim

local ns = vim.api.nvim_create_namespace("kivi")

local M = {}

local PendingUI = {}
PendingUI.__index = PendingUI
M.PendingUI = PendingUI

function PendingUI.open(source, layout, new)
  local bufnr
  if not new and vim.bo.filetype == source.filetype then
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
  -- NOTICE: different from vim.wo.option
  vim.cmd("setlocal nonumber")
  vim.cmd("setlocal nolist")

  local tbl = {bufnr = bufnr, _window_id = window_id}
  return setmetatable(tbl, PendingUI), key
end

local RenderedUI = {}
RenderedUI.__index = RenderedUI

function M._close(self)
  if not vim.api.nvim_buf_is_valid(self.bufnr) then
    return
  end
  return windowlib.close(self._window_id)
end

function M._redraw(self, root, source, history, opts, target_path)
  local lines = {}
  local nodes = {}
  local index = 1
  root:walk(function(node, depth)
    local space = ("  "):rep(depth - 1)
    table.insert(lines, space .. node.value)
    node.index = index -- HACK
    index = index + 1
    table.insert(nodes, node)
  end)

  local tbl = {
    bufnr = self.bufnr,
    _selected = {},
    _window_id = self._window_id,
    _nodes = nodes,
    _selection_hl_factory = highlights.new_factory("kivi-selection-highlight", self.bufnr),
  }
  local ui = setmetatable(tbl, RenderedUI)
  ui:_set_lines(lines, source, history, root.path, opts, target_path)

  return ui
end

PendingUI.close = M._close
RenderedUI.close = M._close
PendingUI.redraw = M._redraw
RenderedUI.redraw = M._redraw

function RenderedUI._set_lines(self, lines, source, history, current_path, opts, target_path)
  local origin_row = vim.api.nvim_win_get_cursor(self._window_id)[1]

  vim.bo[self.bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, lines)
  vim.bo[self.bufnr].modifiable = false

  source:highlight(self.bufnr, self._nodes, opts)
  vim.api.nvim_buf_set_extmark(self.bufnr, ns, 0, 0, {end_line = 1, hl_group = "Comment"})

  if opts.expand then
    cursorlib.set_row(origin_row, self._window_id, self.bufnr)
    return
  end

  local latest_path = target_path or source:init_path() or history.latest_path
  local ok = false
  if latest_path ~= nil then
    for i, node in ipairs(self._nodes) do
      if node.path:get() == latest_path and i ~= 1 then
        cursorlib.set_row(i, self._window_id, self.bufnr)
        ok = true
        break
      end
    end
  end
  if not ok then
    ok = history:restore(current_path:get(), self._window_id, self.bufnr)
  end
  if not ok and latest_path ~= current_path:get() then
    cursorlib.set_row(2, self._window_id, self.bufnr)
  end
end

function RenderedUI.selected_nodes(self, action_name, range)
  if action_name ~= "toggle_selection" and not vim.tbl_isempty(self._selected) then
    local nodes = vim.tbl_values(self._selected)
    table.sort(nodes, function(a, b)
      return a.index < b.index
    end)
    return nodes
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

vim.cmd("highlight default link KiviSelected Statement")

return M
