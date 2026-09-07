local asynclib = require("kivi.lib.async")

local M = {}

--- @async
--- @param ctx KiviContext
function M.action_open(nodes, _, ctx)
  asynclib.all(vim
    .iter(nodes)
    :map(function(node)
      --- @async
      return function()
        require("kivi.controller").navigate(ctx, node.path)
      end
    end)
    :totable())
end

--- @async
function M.action_tab_open(nodes)
  asynclib.all(vim
    .iter(nodes)
    :map(function(node)
      --- @async
      return function()
        require("kivi.controller").open({ path = node.path, layout = { type = "tab" } })
      end
    end)
    :totable())
end

--- @async
function M.action_vsplit_open(nodes)
  asynclib.all(vim
    .iter(nodes)
    :map(function(node)
      --- @async
      return function()
        require("kivi.controller").open({ path = node.path, layout = { type = "vertical" } })
      end
    end)
    :totable())
end

M.action_child = M.action_open

M.is_parent = true

local file_kind = require("kivi.handler.kind.file")
return setmetatable(M, {
  __index = function(_, k)
    return rawget(M, k) or file_kind[k]
  end,
})
