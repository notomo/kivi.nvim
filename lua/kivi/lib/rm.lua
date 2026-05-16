local M = {}

local function _execute(path, type)
  local f

  if type == "directory" then
    local fs = vim.uv.fs_scandir(path)
    if fs then
      while true do
        local file, _type = vim.uv.fs_scandir_next(fs)
        if not file then
          break
        end
        _execute(require("kivi.lib.path").join(path, file), _type)
      end
    end
    f = vim.uv.fs_rmdir
  else
    f = vim.uv.fs_unlink
  end

  local result, err, err_name = f(path)
  if result == nil and err_name ~= "ENOENT" then
    error(err)
  end
end

function M.execute(path)
  local stat, err, err_name = vim.uv.fs_lstat(path)
  if stat then
    _execute(path, stat.type)
  elseif err_name ~= "ENOENT" then
    error(err)
  end
end

return M
