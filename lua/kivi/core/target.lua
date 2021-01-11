local filelib = require("kivi/lib/file")

local M = {}

local Target = {}
Target.__index = Target
M.Target = Target

function Target.new(name)
  vim.validate({name = {name, "string", true}})
  local tbl = {_name = name}
  return setmetatable(tbl, Target)
end

function Target.path(self)
  local target = self[self._name]
  if target == nil then
    return nil
  end
  return target()
end

M.project_root_patterns = {".git"}

function Target.project()
  for _, pattern in ipairs(M.project_root_patterns) do
    local found = filelib.find_upward_dir(pattern)
    if found ~= nil then
      return found
    end
  end

  return "."
end

function Target.current()
  return nil
end

return M
