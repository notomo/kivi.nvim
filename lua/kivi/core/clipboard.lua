local messagelib = require("kivi.lib.message")

local _clipboards = {}

--- @class KiviClipboard
--- @field private _nodes table
--- @field private _has_cut boolean
local Clipboard = {}
Clipboard.__index = Clipboard

--- @param source_name string
function Clipboard.new(source_name)
  local clipboard = _clipboards[source_name]
  if clipboard ~= nil then
    return clipboard
  end

  local tbl = {
    _nodes = {},
    _has_cut = false,
  }
  local self = setmetatable(tbl, Clipboard)
  _clipboards[source_name] = self
  return self
end

function Clipboard.copy(self, nodes)
  self._nodes = nodes
  self._has_cut = false
  messagelib.info(
    "copied:",
    vim
      .iter(nodes)
      :map(function(node)
        return node.path
      end)
      :totable()
  )
end

function Clipboard.cut(self, nodes)
  self._nodes = nodes
  self._has_cut = true
  messagelib.info(
    "cut:",
    vim
      .iter(nodes)
      :map(function(node)
        return node.path
      end)
      :totable()
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
