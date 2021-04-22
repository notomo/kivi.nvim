local M = {}

local find = function(path)
  local ok, module = pcall(require, path)
  if not ok then
    return nil
  end
  return module
end

local function set_base(target, base)
  local meta = getmetatable(target)
  if meta == nil then
    return setmetatable(target, base)
  end
  if target == base or target == meta then
    return target
  end
  return setmetatable(target, set_base(meta, base))
end
M.set_base = set_base

-- for app

function M.find_source(name)
  return find("kivi/source/" .. name)
end

function M.find_kind(name)
  return find("kivi/kind/" .. name)
end

return M
