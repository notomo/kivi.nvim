local M = {}

-- NOTE: This function is replaced in testing.
function M.read(msg)
  return vim.fn.input(msg)
end

local InputReader = {}
InputReader.__index = InputReader

function InputReader.confirm(self, message)
  local msg = ("%s y/n: "):format(message)
  local input = self:get(msg)
  return input == "y"
end

function InputReader.get(_, message)
  vim.fn.inputsave()
  local input = M.read(message)
  vim.fn.inputrestore()
  return input
end

function M.reader()
  return setmetatable({}, InputReader)
end

return M
