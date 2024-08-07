local M = {}

function M.confirm(message, nodes)
  local paths = vim
    .iter(nodes)
    :map(function(node)
      return node.path
    end)
    :totable()
  local target = table.concat(paths, "\n")
  local msg = ("%s\n%s"):format(target, message)
  return require("kivi.lib.input").reader():confirm(msg)
end

return M
