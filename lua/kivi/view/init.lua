local windowlib = require("kivi.lib.window")
local cursorlib = require("kivi.lib.cursor")
local Layout = require("kivi.view.layout")
local Nodes = require("kivi.core.nodes")
local Context = require("kivi.core.context")
local vim = vim

--- @class KiviView
--- @field private _nodes KiviNodes
--- @field bufnr integer
local View = {}
View.__index = View

local _promise = nil

function View.open(source, open_opts)
  local bufnr = open_opts.bufnr or vim.api.nvim_create_buf(false, true)

  local key = ("%s/%d"):format(source.name, bufnr)
  vim.api.nvim_buf_set_name(bufnr, "kivi://" .. key .. "/kivi")
  vim.bo[bufnr].filetype = ("kivi-%s"):format(source.name)
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].modifiable = false

  Layout.open(bufnr, open_opts.layout)
  vim.api.nvim_create_autocmd({ "BufReadCmd" }, {
    buffer = bufnr,
    callback = function()
      local ctx = Context.get(bufnr)
      if type(ctx) == "string" then
        return
      end
      _promise = require("kivi.core.loader").reload(bufnr, ctx:last_position().path)
    end,
  })

  local tbl = {
    bufnr = bufnr,
    _nodes = Nodes.new({}),
  }
  return setmetatable(tbl, View), key
end

--- @param nodes KiviNodes
function View.redraw(self, nodes)
  self._nodes = nodes
  if not vim.api.nvim_buf_is_valid(self.bufnr) then
    return
  end

  vim.bo[self.bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(
    self.bufnr,
    0,
    -1,
    false,
    nodes:map(function(node)
      local indent = ("  "):rep(node.depth - 1)
      return indent .. node.value
    end)
  )
  vim.bo[self.bufnr].modifiable = false
  vim.bo[self.bufnr].modified = false
end

function View.redraw_buffer(self)
  -- NOTICE: This works only for the current window.
  vim.api.nvim__redraw({ buf = self.bufnr, range = { vim.fn.line("w0"), vim.fn.line("w$") } })
end

--- @param history KiviHistory
--- @param cursor_line_path string?
function View.move_cursor(self, history, cursor_line_path)
  if not cursor_line_path then
    return false
  end

  local node = self._nodes:find(cursor_line_path)
  if not node then
    return false
  end

  cursorlib.set_row_by_buffer(node.index, self.bufnr)

  local parent = node:parent_or_root()
  local position = history:stored(parent.path)
  if position ~= nil then
    vim.fn.winrestview({ topline = position.first_row })
  end
  return true
end

function View.init_cursor(self)
  cursorlib.set_row_by_buffer(2, self.bufnr)
end

--- @param history KiviHistory
--- @param path string
function View.restore_cursor(self, history, path)
  local position = history:stored(path)
  if position ~= nil then
    cursorlib.set_row_by_buffer(position.cursor_row, self.bufnr)
    vim.fn.winrestview({ topline = position.first_row })
    return true
  end
  return false
end

function View.close(self)
  return windowlib.close_by_buffer(self.bufnr)
end

function View.selected_nodes(self, action_name, range)
  return Nodes.from_selected(self:_selected_nodes(action_name, range))
end

function View._selected_nodes(self, action_name, range)
  if action_name ~= "toggle_selection" and self._nodes:has_selections() then
    return self._nodes:selected()
  end

  if range ~= nil then
    return self._nodes:range(range.first, range.last)
  end

  return { self:current_node() }
end

function View.current_node(self)
  return self._nodes[vim.fn.line(".")]
end

function View.toggle_selections(self, nodes)
  self._nodes = self._nodes:toggle_selections(nodes)
  vim.api.nvim__redraw({ buf = self.bufnr, range = { nodes[1].index - 1, nodes[#nodes].index } })
end

function View.reset_selections(self, action_name)
  if action_name == "toggle_selection" then
    return
  end
  self._nodes = self._nodes:clear_selections()
  self:redraw_buffer()
end

vim.api.nvim_set_hl(0, "KiviSelected", { default = true, link = "Statement" })

function View._highlight_win(_, _, bufnr, topline, botline_guess)
  local ctx = Context.get(bufnr)
  if type(ctx) == "string" then
    return false
  end
  ctx.ui:highlight(ctx.source, ctx.opts, topline, botline_guess)
  return false
end

local Decorator = require("kivi.vendor.misclib.decorator")

local ns = vim.api.nvim_create_namespace("kivi-highlight")
vim.api.nvim_set_decoration_provider(ns, {})
vim.api.nvim_set_decoration_provider(ns, { on_win = View._highlight_win })

local highlight_opts = {
  priority = vim.hl.priorities.user - 1,
}

function View.highlight(self, source, opts, first_line, last_line)
  if vim.api.nvim_buf_get_text(self.bufnr, 0, 0, 0, 1, {})[1] == "" then
    return
  end

  local decorator = Decorator.new(ns, self.bufnr, true)
  local nodes = self._nodes:range(first_line + 1, last_line + 1)
  for i, node in ipairs(nodes) do
    local row = first_line + i - 1
    source.highlight_one(decorator, row, node, opts)
    if self._nodes:is_selected(node.path) then
      decorator:highlight_line("KiviSelected", row, highlight_opts)
    end
  end
  if first_line == 0 then
    decorator:highlight_line("Comment", 0, highlight_opts)
  end
end

-- for test
function View.promises()
  if _promise then
    local promise = _promise
    _promise = nil
    return { promise }
  end
  return {}
end

return View
