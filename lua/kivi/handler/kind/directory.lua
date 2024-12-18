local Promise = require("kivi.vendor.promise")

local M = {}

--- @param ctx KiviContext
function M.action_open(nodes, _, ctx)
  return Promise.all(vim
    .iter(nodes)
    :map(function(node)
      return require("kivi.controller").navigate(ctx, node.path)
    end)
    :totable()):next(function() end)
end

function M.action_tab_open(nodes)
  return Promise.all(vim
    .iter(nodes)
    :map(function(node)
      return require("kivi.controller").open({ path = node.path, layout = { type = "tab" } })
    end)
    :totable()):next(function() end)
end

function M.action_vsplit_open(nodes)
  return Promise.all(vim
    .iter(nodes)
    :map(function(node)
      return require("kivi.controller").open({ path = node.path, layout = { type = "vertical" } })
    end)
    :totable()):next(function() end)
end

M.action_child = M.action_open

M.is_parent = true

local file_kind = require("kivi.handler.kind.file")
return setmetatable(M, {
  __index = function(_, k)
    return rawget(M, k) or file_kind[k]
  end,
})
