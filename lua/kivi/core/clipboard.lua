local _clipboards = {}

--- @class KiviClipboard
--- @field private _nodes KiviNode[]
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
  require("kivi.lib.message").info_with(
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
  require("kivi.lib.message").info_with(
    "cut:",
    vim
      .iter(nodes)
      :map(function(node)
        return node.path
      end)
      :totable()
  )
end

function Clipboard.peek(self)
  return self._nodes, self._has_cut
end

function Clipboard.clear(self)
  self._nodes = {}
  self._has_cut = false
end

return Clipboard
