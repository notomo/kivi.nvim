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

M.find_source = function(name)
  return find("kivi/source/" .. name)
end

M.find_kind = function(name)
  return find("kivi/kind/" .. name)
end

local plugin_name = vim.split((...):gsub("%.", "/"), "/", true)[1]
M.cleanup = function()
  local dir = plugin_name .. "/"
  for key in pairs(package.loaded) do
    if (vim.startswith(key, dir) or key == plugin_name) and key ~= "kivi/lib/_persist" then
      package.loaded[key] = nil
    end
  end
  vim.api.nvim_command("doautocmd User KiviSourceLoad")
end

return M
