local M = {}

M.read = function(msg)
  return vim.fn.input(msg)
end

M.reader = function()
  return function(msg)
    vim.fn.inputsave()
    local input = M.read(msg)
    vim.fn.inputrestore()
    return input
  end
end

return M
