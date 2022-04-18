local repository = require("kivi.lib.repository").Repository.new("creator")
local messagelib = require("kivi.lib.message")
local windowlib = require("kivi.lib.window")

local M = {}

local Creator = {}
Creator.__index = Creator
M.Creator = Creator

Creator.path = "/kivi-creator"

function Creator.open(kind, loader, base_node)
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
  vim.api.nvim_buf_set_name(bufnr, "kivi://" .. bufnr .. Creator.path)
  vim.cmd("doautocmd BufRead") -- HACK?

  vim.cmd(([[autocmd BufWriteCmd <buffer=%s> ++nested lua require('kivi.command').write(%s)]]):format(bufnr, bufnr))
  vim.cmd(([[autocmd BufWipeout <buffer=%s> lua require("kivi.command").delete(%s)]]):format(bufnr, bufnr))

  local tbl = {
    _bufnr = bufnr,
    _base_node = base_node,
    _kind = kind,
    _loader = loader,
    _window_id = window_id,
  }
  local creator = setmetatable(tbl, Creator)
  repository:set(bufnr, creator)

  vim.cmd("startinsert")
end

function Creator.write(self)
  local lines = vim.api.nvim_buf_get_lines(self._bufnr, 0, -1, true)
  local paths = {}
  for _, line in ipairs(lines) do
    if line ~= "" then
      table.insert(paths, self._base_node.path:join(line))
    end
  end

  local success = {}
  local errors = {}
  for i, path in ipairs(paths) do
    if path:exists() then
      table.insert(errors, { path = path, msg = "already exists: " .. path:get() })
      goto continue
    end

    local err = self._kind:create(path)
    if err ~= nil then
      table.insert(errors, { path = path, msg = err })
      goto continue
    end

    success[i] = path
    ::continue::
  end

  vim.api.nvim_buf_set_lines(
    self._bufnr,
    0,
    -1,
    false,
    vim.tbl_map(function(e)
      return self._base_node.path:relative(e.path)
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
    for _, p in ipairs(path:between(self._base_node.path)) do
      expanded[p:get()] = true
    end
    last_index = i
  end

  local cursor_line_path = nil
  if success[last_index] ~= nil then
    cursor_line_path = success[last_index]:get()
  end

  self._loader:reload(cursor_line_path, expanded)
end

function Creator.match(path)
  local pattern = vim.pesc(Creator.path) .. "$"
  return path:match(pattern)
end

function Creator.write_from(bufnr)
  local creator = repository:get(bufnr)
  if creator == nil then
    return
  end
  return creator:write()
end

function Creator.delete_from(bufnr)
  repository:delete(bufnr)
end

return M
