local messagelib = require("kivi.lib.message")

local _clipboards = {}

local Clipboard = {}
Clipboard.__index = Clipboard

function Clipboard.new(source_name)
  vim.validate({ source_name = { source_name, "string" } })
  local clipboard = _clipboards[source_name]
  if clipboard ~= nil then
    return clipboard
  end

  local tbl = { _nodes = {}, _has_cut = false }
  local self = setmetatable(tbl, Clipboard)
  _clipboards[source_name] = self
  return self
end

function Clipboard.copy(self, nodes)
  self._nodes = nodes
  self._has_cut = false
  messagelib.info(
    "copied:",
    vim.tbl_map(function(node)
      return node.path:get()
    end, nodes)
  )
end

function Clipboard.cut(self, nodes)
  self._nodes = nodes
  self._has_cut = true
  messagelib.info(
    "cut:",
    vim.tbl_map(function(node)
      return node.path:get()
    end, nodes)
  )
end

function Clipboard.pop(self)
  local nodes = self._nodes
  local has_cut = self._has_cut
  self._nodes = {}
  self._has_cut = false
  return nodes, has_cut
end

return Clipboard
