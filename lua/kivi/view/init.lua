local windowlib = require("kivi.lib.window")
local cursorlib = require("kivi.lib.cursor")
local bufferlib = require("kivi.vendor.misclib.buffer")
local Layout = require("kivi.view.layout")
local Nodes = require("kivi.core.nodes")
local Context = require("kivi.core.context")
local vim = vim

local View = {}
View.__index = View

function View.open(source, open_opts)
  local bufnr = vim.api.nvim_create_buf(false, true)

  local key = ("%s/%d"):format(source.name, bufnr)
  vim.api.nvim_buf_set_name(bufnr, "kivi://" .. key .. "/kivi")
  vim.bo[bufnr].filetype = ("kivi-%s"):format(source.name)
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].modifiable = false

  Layout.new(open_opts.layout):open(bufnr)
  vim.api.nvim_set_option_value("number", false, { scope = "local" })
  vim.api.nvim_set_option_value("list", false, { scope = "local" })
  vim.api.nvim_create_autocmd({ "BufReadCmd" }, {
    buffer = bufnr,
    callback = function()
      require("kivi.command").read(bufnr)
    end,
  })

  local tbl = { bufnr = bufnr, _nodes = Nodes.new({}) }
  return setmetatable(tbl, View), key
end

function View.redraw(self, nodes)
  self._nodes = nodes
  bufferlib.set_lines_as_modifiable(
    self.bufnr,
    0,
    -1,
    false,
    nodes:map(function(node)
      local indent = ("  "):rep(node.depth - 1)
      return indent .. node.value
    end)
  )
end

function View.move_cursor(self, path)
  vim.validate({ path = { path, "string", true } })
  if not path then
    return false
  end

  local node = self._nodes:find(path)
  if node then
    cursorlib.set_row_by_buffer(node.index, self.bufnr)
    return true
  end

  return false
end

function View.init_cursor(self)
  cursorlib.set_row_by_buffer(2, self.bufnr)
end

function View.restore_cursor(self, history, path)
  vim.validate({ history = { history, "table" }, path = { path, "string" } })
  local row = history:stored(path)
  if row ~= nil then
    cursorlib.set_row_by_buffer(row, self.bufnr)
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

  return { self._nodes[vim.fn.line(".")] }
end

function View.toggle_selections(self, nodes)
  self._nodes = self._nodes:toggle_selections(nodes)
  vim.api.nvim__buf_redraw_range(self.bufnr, nodes[1].index - 1, nodes[#nodes].index)
end

function View.reset_selections(self, action_name)
  if action_name == "toggle_selection" then
    return
  end
  self._nodes = self._nodes:clear_selections()
  -- NOTICE: This works only for the current window.
  vim.api.nvim__buf_redraw_range(self.bufnr, vim.fn.line("w0"), vim.fn.line("w$"))
end

vim.cmd("highlight default link KiviSelected Statement")

function View._highlight_win(_, _, bufnr, topline, botline_guess)
  local ctx, err = Context.get(bufnr)
  if err ~= nil then
    return false
  end
  ctx.ui:highlight(ctx.source, ctx.opts, topline, botline_guess)
  return false
end

local ns = vim.api.nvim_create_namespace("kivi-highlight")
vim.api.nvim_set_decoration_provider(ns, {})
vim.api.nvim_set_decoration_provider(ns, { on_win = View._highlight_win })

function View.highlight(self, source, opts, first_line, last_line)
  local nodes = self._nodes:range(first_line + 1, last_line)
  source:highlight(self.bufnr, first_line, nodes, opts)

  local highlighter = source.highlights:create(self.bufnr)
  if first_line == 0 then
    highlighter:add_line("Comment", 0)
  end

  highlighter:filter("KiviSelected", first_line, nodes, function(node)
    return self._nodes:is_selected(node.path)
  end)
end

return View
