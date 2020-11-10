local repository = require("kivi/core/repository")
local pathlib = require("kivi/lib/path")

local M = {}

local ns = vim.api.nvim_create_namespace("kivi-renamer")

local Renamer = {}
Renamer.__index = Renamer
M.Renamer = Renamer

function Renamer.open(executor, base_node, rename_items, has_cut)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")

  local lines = vim.tbl_map(function(item)
    return base_node:to_relative_path(item.to or item.from)
  end, rename_items)
  vim.api.nvim_buf_set_lines(bufnr, 0, 0, true, {""})
  vim.api.nvim_buf_set_lines(bufnr, 1, -1, true, lines)

  vim.api.nvim_buf_set_extmark(bufnr, ns, 0, 0, {virt_text = {{base_node.path, "Comment"}}})
  for i, line in ipairs(lines) do
    vim.api.nvim_buf_set_extmark(bufnr, ns, i, #line, {virt_text = {{"<- " .. line, "Comment"}}})
  end

  local width = 75
  local height = #rename_items
  local window_id = vim.api.nvim_open_win(bufnr, true, {
    width = width,
    height = height + 1,
    relative = "editor",
    row = math.floor(vim.o.lines / 2) - math.floor(height / 2),
    col = math.floor(vim.o.columns / 2) - math.floor(width / 2),
    anchor = "NW",
    focusable = true,
    external = false,
    style = "minimal",
  })
  vim.api.nvim_win_set_option(window_id, "signcolumn", "yes:1")
  vim.api.nvim_win_set_option(window_id, "winhighlight", "SignColumn:NormalFloat")
  vim.api.nvim_win_set_cursor(window_id, {2, 0})
  vim.api.nvim_buf_set_option(bufnr, "buftype", "acwrite")
  vim.api.nvim_buf_set_option(bufnr, "modified", false)
  vim.api.nvim_buf_set_name(bufnr, "kivi://" .. bufnr .. "/kivi-renamer")

  local cmd = ("autocmd BufWriteCmd <buffer=%s> ++nested lua require('kivi/view/renamer').write(%s)"):format(bufnr, bufnr)
  vim.api.nvim_command(cmd)

  local tbl = {
    _bufnr = bufnr,
    _lines = lines,
    _base_node = base_node,
    _has_cut = has_cut,
    _executor = executor,
  }
  local renamer = setmetatable(tbl, Renamer)
  repository.set(bufnr, renamer)
end

function Renamer.write(self)
  local lines = vim.api.nvim_buf_get_lines(self._bufnr, 1, -1, true)
  local items = {}
  for i, line in ipairs(lines) do
    local original_line = self._lines[i]
    if original_line == nil then
      break
    end
    if line == original_line then
      goto continue
    end
    table.insert(items, {
      from = pathlib.join(self._base_node.path, original_line),
      to = pathlib.join(self._base_node.path, line),
    })
    ::continue::
  end

  local result = self._executor:rename(items, self._has_cut)

  for i in pairs(result.success) do
    local line = lines[i]
    vim.api.nvim_buf_set_extmark(self._bufnr, ns, i, #line, {
      virt_text = {{"<- " .. line, "Comment"}},
    })
    self._lines[i] = line
  end

  if #result.already_exists == 0 then
    vim.api.nvim_buf_set_option(self._bufnr, "modified", false)
    self._has_cut = true
    self._executor:reload()
  end
end

M.write = function(bufnr)
  local renamer = repository.get(bufnr)
  if renamer == nil then
    return
  end
  renamer:write()
end

return M
