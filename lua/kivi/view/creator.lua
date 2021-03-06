local wraplib = require("kivi/lib/wrap")
local messagelib = require("kivi/lib/message")
local windowlib = require("kivi/lib/window")

local persist = {creators = {}}

local M = {}

local Creator = {}
Creator.__index = Creator
M.Creator = Creator

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
  })
  vim.wo[window_id].signcolumn = "yes:1"
  vim.wo[window_id].winhighlight = "SignColumn:NormalFloat"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].buftype = "acwrite"
  vim.bo[bufnr].modified = false
  vim.api.nvim_buf_set_name(bufnr, "kivi://" .. bufnr .. "/kivi-creator")
  vim.cmd("doautocmd BufRead") -- HACK?

  local cmd = ("autocmd BufWriteCmd <buffer=%s> ++nested lua require('kivi/view/creator').write(%s)"):format(bufnr, bufnr)
  vim.cmd(cmd)

  local tbl = {
    _bufnr = bufnr,
    _base_node = base_node,
    _kind = kind,
    _loader = loader,
    _window_id = window_id,
  }
  local creator = setmetatable(tbl, Creator)
  persist.creators[bufnr] = creator

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

  local result = self._kind:create(paths)

  vim.api.nvim_buf_set_lines(self._bufnr, 0, -1, false, vim.tbl_map(function(e)
    return self._base_node.path:relative(e.path)
  end, result.errors))

  if #result.errors == 0 then
    vim.bo[self._bufnr].modified = false
    windowlib.close(self._window_id)
  else
    for _, e in ipairs(result.errors) do
      messagelib.warn(e.msg)
    end
  end

  local last_index = 0
  local expanded = {}
  for i, path in pairs(result.success) do
    for _, p in ipairs(path:between(self._base_node.path)) do
      expanded[p:get()] = true
    end
    last_index = i
  end

  local target_path = nil
  if result.success[last_index] ~= nil then
    target_path = result.success[last_index]:get()
  end

  self._loader:load(nil, target_path, {expanded = expanded})
end

M.write = function(bufnr)
  local creator = persist.creators[bufnr]
  if creator == nil then
    return
  end
  wraplib.traceback(function()
    return creator:write()
  end)
end

return M
