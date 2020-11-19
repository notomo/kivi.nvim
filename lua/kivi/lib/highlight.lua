local vim = vim

local M = {}

local Highlighter = {}
Highlighter.__index = Highlighter

function Highlighter.add(self, hl_group, row, start_col, end_col)
  vim.api.nvim_buf_add_highlight(self.bufnr, self.ns, hl_group, row, start_col, end_col)
end

function Highlighter.set_virtual_text(self, row, chunks)
  vim.api.nvim_buf_set_virtual_text(self.bufnr, self.ns, row, chunks, {})
end

function Highlighter.filter(self, hl_group, elements, condition)
  for i, e in ipairs(elements) do
    if condition(e) then
      self:add(hl_group, i - 1, 0, -1)
    end
  end
end

local Factory = {}
Factory.__index = Factory

function Factory.create(self, bufnr)
  bufnr = bufnr or self.bufnr
  local highlighter = {bufnr = bufnr, ns = self.ns}
  return setmetatable(highlighter, Highlighter)
end

function Factory.reset(self, bufnr)
  bufnr = bufnr or self.bufnr
  local highlighter = self:create(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, self.ns, 0, -1)
  return highlighter
end

M.new_factory = function(key, bufnr)
  vim.validate({key = {key, "string"}, bufnr = {bufnr, "number", true}})
  local ns = vim.api.nvim_create_namespace(key)
  local factory = {ns = ns, bufnr = bufnr}
  return setmetatable(factory, Factory)
end

local attrs = {
  ctermfg = {"fg", "cterm"},
  guifg = {"fg", "gui"},
  ctermbg = {"bg", "cterm"},
  guibg = {"bg", "gui"},
}
M.default = function(name, attributes)
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
  vim.api.nvim_command(cmd)
end

return M
