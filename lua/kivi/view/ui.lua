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

function PendingUI.redraw(self, bufnr, collect_result)
  return M._redraw(self, bufnr, collect_result)
end

function PendingUI.close(self)
  return windowlib.close(self._window_id)
end

function RenderedUI.redraw(self, bufnr, collect_result)
  return M._redraw(self, bufnr, collect_result)
end

function RenderedUI.close(self)
  return windowlib.close(self._window_id)
end

M._redraw = function(self, bufnr, collect_result)
  local tbl = {
    _kind_name = collect_result.source.kind_name,
    _selected = {},
    _window_id = self._window_id,
  }
  local items, ok = collect_result:get()
  if ok then
    M._set_lines(bufnr, items, collect_result.source)
    tbl._items = items
    -- TODO: else job
  end

  return setmetatable(tbl, RenderedUI)
end

M._set_lines = function(bufnr, items, source)
  local lines = vim.tbl_map(function(item)
    return item.value
  end, items)

  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable = false

  source:highlight(bufnr, items)
end

function RenderedUI.item_groups(self, action_name, range)
  local items = self:_selected_items(action_name, range)
  local item_groups = listlib.group_by(items, function(item)
    return item.kind_name or self._kind_name
  end)
  if #item_groups == 0 then
    table.insert(item_groups, {"base", {}})
  end
  return item_groups
end

function RenderedUI._selected_items(self, action_name, range)
  -- TODO: select action
  if action_name ~= "toggle_selection" and not vim.tbl_isempty(self._selected) then
    local selected = vim.tbl_values(self._selected)
    table.sort(selected, function(a, b)
      return a.index < b.index
    end)
    return selected
  end

  if range ~= nil then
    local items = {}
    for i = range.first, range.last, 1 do
      table.insert(items, self._items[i])
    end
    return items
  end

  return {self._items[vim.fn.line(".")]}
end

return M
