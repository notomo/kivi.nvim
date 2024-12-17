local M = {}

local apply = function(nodes, ignored, window_id)
  for node in nodes:iter() do
    if ignored[node.path] then
      node.is_git_ignored = true
    end
  end
  vim.schedule(function()
    if not vim.api.nvim_win_is_valid(window_id) then
      return
    end
    vim.api.nvim__redraw({ win = window_id, valid = false })
  end)
end

local repository_ignored = {}

function M.apply(cwd, nodes, window_id, reload)
  local git_root = vim.fs.root(cwd, { ".git" })
  if not git_root then
    return
  end

  local already = repository_ignored[git_root]
  if not reload and already then
    apply(nodes, already, window_id)
    return
  end

  vim.system({
    "git",
    "-C",
    git_root,
    "--no-optional-locks",
    "status",
    "--null",
    "--ignored=matching",
  }, {
    cwd = git_root,
    stderr = function(_, data)
      if not data then
        return
      end
      vim.schedule(function()
        require("kivi.lib.message").warn(data)
      end)
    end,
  }, function(o)
    if o.code ~= 0 then
      return
    end
    local ignored = {}
    vim.iter(vim.split(o.stdout, "\0", { plain = true, trimempty = true })):each(function(line)
      local status, file_path = unpack(vim.split(line, " ", { plain = true, trimempty = true }))
      if status ~= "!!" then
        return
      end
      local path = vim.fs.joinpath(git_root, file_path)
      ignored[path] = true
    end)
    repository_ignored[git_root] = ignored
    apply(nodes, ignored, window_id)
  end)
end

return M
