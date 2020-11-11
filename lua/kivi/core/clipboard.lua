local persist = {clipboards = {}}

local M = {}

local Clipboard = {}
Clipboard.__index = Clipboard
M.Clipboard = Clipboard

function Clipboard.new(source_name)
  vim.validate({source_name = {source_name, "string"}})
  local clipboard = persist.clipboards[source_name]
  if clipboard ~= nil then
    return clipboard
  end

  local tbl = {_paths = {}, _has_cut = false}
  local self = setmetatable(tbl, Clipboard)
  persist.clipboards[source_name] = self
  return self
end

function Clipboard.copy(self, nodes)
  self._paths = nodes
  self._has_cut = false
end

function Clipboard.cut(self, nodes)
  self:copy(nodes)
  self._has_cut = true
end

function Clipboard.pop(self)
  local paths = self._paths
  local has_cut = self._has_cut
  self:copy({})
  return paths, has_cut
end

return M
