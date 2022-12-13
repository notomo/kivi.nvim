local Promise = require("kivi.vendor.promise")

local M = {}

function M.action_open(_, nodes, _, ctx)
  return Promise.all(vim.tbl_map(function(node)
    return require("kivi.controller").navigate(ctx, node.path)
  end, nodes))
end

function M.action_tab_open(_, nodes)
  return Promise.all(vim.tbl_map(function(node)
    return require("kivi.controller").open({ path = node.path, layout = { type = "tab" } })
  end, nodes))
end

function M.action_vsplit_open(_, nodes)
  return Promise.all(vim.tbl_map(function(node)
    return require("kivi.controller").open({ path = node.path, layout = { type = "vertical" } })
  end, nodes))
end

M.action_child = M.action_open

M.is_parent = true

local file_kind = require("kivi.handler.kind.file")
return setmetatable(M, {
  __index = function(_, k)
    return rawget(M, k) or file_kind[k]
  end,
})
