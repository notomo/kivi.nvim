local messagelib = require("kivi.lib.message")
local windowlib = require("kivi.lib.window")
local pathlib = require("kivi.lib.path")

local Creator = {}
Creator.__index = Creator

local _promise = nil

function Creator.open(kind, tree_bufnr, base_node)
  local bufnr = vim.api.nvim_create_buf(false, true)

  local width = 75
  local height = math.floor(vim.o.lines / 2)
  local window_id = vim.api.nvim_open_win(bufnr, true, {
    width = width,
    height = height,
    relative = "editor",
    row = math.floor(vim.o.lines / 2) - math.floor(height / 2),
    col = math.floor(vim.o.columns / 2) - math.floor(width / 2),
    anchor = "NW",
    focusable = true,
    external = false,
    style = "minimal",
    border = { { " ", "NormalFloat" } },
  })
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].buftype = "acwrite"
  vim.bo[bufnr].modified = false
  vim.api.nvim_buf_set_name(bufnr, "kivi://" .. bufnr .. "/kivi-creator")
  vim.api.nvim_exec_autocmds("BufRead", { modeline = false }) -- HACK?

  local tbl = {
    _bufnr = bufnr,
    _base_node = base_node,
    _kind = kind,
    _tree_bufnr = tree_bufnr,
    _window_id = window_id,
  }
  local creator = setmetatable(tbl, Creator)

  vim.cmd.startinsert()

  vim.api.nvim_create_autocmd({ "BufWriteCmd" }, {
    buffer = bufnr,
    nested = true,
    callback = function()
      _promise = creator:write()
    end,
  })
end

function Creator.write(self)
  local lines = vim.api.nvim_buf_get_lines(self._bufnr, 0, -1, true)
  local paths = {}
  for _, line in ipairs(lines) do
    if line ~= "" then
      table.insert(paths, pathlib.join(self._base_node.path, line))
    end
  end

  local success = {}
  local errors = {}
  vim.iter(paths):enumerate():each(function(i, path)
    if self._kind.exists(path) then
      table.insert(errors, { path = path, msg = "already exists: " .. path })
      return
    end

    local err = self._kind.create(path)
    if err then
      table.insert(errors, { path = path, msg = err })
      return
    end

    success[i] = path
  end)

  vim.api.nvim_buf_set_lines(
    self._bufnr,
    0,
    -1,
    false,
    vim.tbl_map(function(e)
      return pathlib.relative(self._base_node.path, e.path)
    end, errors)
  )

  if #errors == 0 then
    vim.bo[self._bufnr].modified = false
    windowlib.close(self._window_id)
  else
    for _, e in ipairs(errors) do
      messagelib.warn(e.msg)
    end
  end

  local last_index = 0
  local expanded = {}
  for i, path in pairs(success) do
    for _, p in ipairs(pathlib.between(path, self._base_node.path)) do
      expanded[p] = true
    end
    last_index = i
  end

  local cursor_line_path = nil
  if success[last_index] ~= nil then
    cursor_line_path = success[last_index]
  end

  return require("kivi.core.loader").reload(self._tree_bufnr, cursor_line_path, expanded)
end

-- for test
function Creator.promises()
  if _promise then
    local promise = _promise
    _promise = nil
    return { promise }
  end
  return {}
end

return Creator
