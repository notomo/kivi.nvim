local windowlib = require("kivi.lib.window")
local cursorlib = require("kivi.lib.cursor")
local bufferlib = require("kivi.lib.buffer")
local Layout = require("kivi.view.layout").Layout
local vim = vim

local M = {}

local View = {}
View.__index = View
M.View = View

View.key_mapping_script = [[
nnoremap <silent> <buffer> <expr> j line('.') == line('$') ? 'gg' : 'j'
nnoremap <silent> <buffer> <expr> k line('.') == 1 ? 'G' : 'k'
nnoremap <buffer> h <Cmd>lua require("kivi").execute("parent")<CR>
nnoremap <buffer> l <Cmd>lua require("kivi").execute("child")<CR>
nnoremap <nowait> <buffer> q <Cmd>quit<CR>]]

function View.open(source, open_opts)
  local bufnr = vim.api.nvim_create_buf(false, true)

  local key = ("%s/%d"):format(source.name, bufnr)
  vim.api.nvim_buf_set_name(bufnr, "kivi://" .. key .. "/kivi")
  vim.bo[bufnr].filetype = source.filetype
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].modifiable = false

  Layout.new(open_opts.layout):open(bufnr)
  -- NOTICE: different from vim.wo.option
  vim.cmd("setlocal nonumber")
  vim.cmd("setlocal nolist")
  vim.cmd(View.key_mapping_script)
  vim.cmd(([[autocmd BufReadCmd <buffer=%s> lua require("kivi.command").Command.new("read", %s)]]):format(bufnr, bufnr))

  local tbl = {bufnr = bufnr, _selected = {}, _nodes = {}}
  return setmetatable(tbl, View), key
end

function View.redraw(self, root)
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
  self._nodes = nodes
  bufferlib.set_lines(self.bufnr, 0, -1, lines)
end

function View.move_cursor(self, path)
  vim.validate({path = {path, "string", true}})
  if not path then
    return false
  end

  for i, node in ipairs(self._nodes) do
    if node.path:get() == path and i ~= 1 then
      cursorlib.set_row_by_buffer(i, self.bufnr)
      return true
    end
  end

  return false
end

function View.init_cursor(self)
  cursorlib.set_row_by_buffer(2, self.bufnr)
end

function View.restore_cursor(self, history, path)
  vim.validate({history = {history, "table"}, path = {path, "string"}})
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

function View.toggle_selections(self, nodes)
  for _, node in ipairs(nodes) do
    if self._selected[node.path] then
      self._selected[node.path] = nil
    else
      self._selected[node.path] = node
    end
  end
  vim.api.nvim__buf_redraw_range(self.bufnr, nodes[1].index - 1, nodes[#nodes].index - 1)
end

function View.reset_selections(self, action_name)
  if action_name == "toggle_selection" then
    return
  end
  self._selected = {}
end

vim.cmd("highlight default link KiviSelected Statement")

function View.highlight(self, source, opts, first_line, last_line)
  local nodes = {}
  for i = first_line + 1, last_line, 1 do
    table.insert(nodes, self._nodes[i])
  end
  source:highlight(self.bufnr, first_line, nodes, opts)

  local highlighter = source.highlights:create(self.bufnr)
  if first_line == 0 then
    highlighter:add_line("Comment", 0)
  end

  highlighter:filter("KiviSelected", first_line, nodes, function(node)
    return self._selected[node.path] ~= nil
  end)
end

return M
