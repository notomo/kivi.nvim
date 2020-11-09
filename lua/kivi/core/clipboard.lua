local persist = {clipborads = {}}

local M = {}

local Clipboard = {}
Clipboard.__index = Clipboard

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

M.create = function(source_name)
  vim.validate({source_name = {source_name, "string"}})
  local clipboard = persist.clipborads[source_name]
  if clipboard ~= nil then
    return clipboard
  end

  local tbl = {_paths = {}, _has_cut = false}
  local self = setmetatable(tbl, Clipboard)
  persist.clipborads[source_name] = self
  return self
end

return M
