local vim = vim

local M = {}

local Highlighter = {}
Highlighter.__index = Highlighter

function Highlighter.new(ns, bufnr)
  vim.validate({ns = {ns, "number"}, bufnr = {bufnr, "number"}})
  local tbl = {_ns = ns, _bufnr = bufnr}
  return setmetatable(tbl, Highlighter)
end

function Highlighter.add(self, hl_group, row, start_col, end_col)
  vim.api.nvim_buf_add_highlight(self._bufnr, self._ns, hl_group, row, start_col, end_col)
end

function Highlighter.filter(self, hl_group, elements, condition)
  for i, e in ipairs(elements) do
    if condition(e) then
      self:add(hl_group, i - 1, 0, -1)
    end
  end
end

local HighlighterFactory = {}
HighlighterFactory.__index = HighlighterFactory
M.HighlighterFactory = HighlighterFactory

function HighlighterFactory.new(key, bufnr)
  vim.validate({key = {key, "string"}, bufnr = {bufnr, "number", true}})
  local ns = vim.api.nvim_create_namespace(key)
  local factory = {_ns = ns, _bufnr = bufnr}
  return setmetatable(factory, HighlighterFactory)
end

function HighlighterFactory.create(self, bufnr)
  vim.validate({bufnr = {bufnr, "number", true}})
  bufnr = bufnr or self._bufnr
  return Highlighter.new(self._ns, bufnr)
end

function HighlighterFactory.reset(self, bufnr)
  vim.validate({bufnr = {bufnr, "number", true}})
  bufnr = bufnr or self._bufnr
  local highlighter = self:create(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, self._ns, 0, -1)
  return highlighter
end

local attrs = {
  ctermfg = {"fg", "cterm"},
  guifg = {"fg", "gui"},
  ctermbg = {"bg", "cterm"},
  guibg = {"bg", "gui"},
}
function M.default(name, attributes)
  local attr = ""
  for key, v in pairs(attributes) do
    local value
    if type(v) == "table" then
      local hl_group, default = unpack(v)
      local attr_key, mode = unpack(attrs[key])
      local id = vim.api.nvim_get_hl_id_by_name(hl_group)
      local attr_value = vim.fn.synIDattr(id, attr_key, mode)
      if attr_value ~= "" then
        value = attr_value
      else
        value = default
      end
    else
      value = v
    end
    attr = attr .. (" %s=%s"):format(key, value)
  end

  local cmd = ("highlight default %s %s"):format(name, attr)
  vim.cmd(cmd)
end

return M
