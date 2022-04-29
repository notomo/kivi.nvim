local vim = vim

local M = {}

local Highlighter = {}
Highlighter.__index = Highlighter

function Highlighter.new(ns, bufnr)
  vim.validate({ ns = { ns, "number" }, bufnr = { bufnr, "number" } })
  local tbl = { _ns = ns, _bufnr = bufnr }
  return setmetatable(tbl, Highlighter)
end

function Highlighter.add_line(self, hl_group, row)
  vim.api.nvim_buf_set_extmark(self._bufnr, self._ns, row, 0, {
    hl_group = hl_group,
    end_line = row + 1,
    ephemeral = true,
  })
end

function Highlighter.filter(self, hl_group, row, elements, condition)
  for i, e in ipairs(elements) do
    if condition(e) then
      self:add_line(hl_group, row + i - 1)
    end
  end
end

local HighlighterFactory = {}
HighlighterFactory.__index = HighlighterFactory
M.HighlighterFactory = HighlighterFactory

function HighlighterFactory.new(key, bufnr)
  vim.validate({ key = { key, "string" }, bufnr = { bufnr, "number", true } })
  local ns = vim.api.nvim_create_namespace(key)
  local factory = { _ns = ns, _bufnr = bufnr }
  return setmetatable(factory, HighlighterFactory)
end

function HighlighterFactory.create(self, bufnr)
  vim.validate({ bufnr = { bufnr, "number", true } })
  bufnr = bufnr or self._bufnr
  return Highlighter.new(self._ns, bufnr)
end

function HighlighterFactory.reset(self, bufnr)
  vim.validate({ bufnr = { bufnr, "number", true } })
  bufnr = bufnr or self._bufnr
  local highlighter = self:create(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, self._ns, 0, -1)
  return highlighter
end

function M.default(name, attributes)
  local new_attributes = {}
  for key, value in pairs(attributes) do
    if type(value) == "table" then
      local hl_group, attribute = unpack(value)
      local hl = vim.api.nvim_get_hl_by_name(hl_group, true)
      new_attributes[key] = hl[attribute]
    else
      new_attributes[key] = value
    end
  end
  new_attributes.default = true
  vim.api.nvim_set_hl(0, name, new_attributes)
end

return M
