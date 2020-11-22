local messagelib = require("kivi/lib/message")

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
  vim.api.nvim_command("doautocmd BufRead") -- HACK?

  local cmd = ("autocmd BufWriteCmd <buffer=%s> ++nested lua require('kivi/view/creator').write(%s)"):format(bufnr, bufnr)
  vim.api.nvim_command(cmd)

  local tbl = {_bufnr = bufnr, _base_node = base_node, _kind = kind, _loader = loader}
  local creator = setmetatable(tbl, Creator)
  persist.creators[bufnr] = creator

  vim.api.nvim_command("startinsert")
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

  vim.api.nvim_buf_set_lines(self._bufnr, 0, -1, false, vim.tbl_map(function(path)
    return self._base_node.path:relative(path)
  end, result.already_exists))

  if #result.already_exists == 0 then
    vim.api.nvim_buf_set_option(self._bufnr, "modified", false)
    vim.api.nvim_command("quit")
  else
    messagelib.warn("already exists:", vim.tbl_map(function(path)
      return path:get()
    end, result.already_exists))
  end

  local target_path = nil
  if result.success[1] ~= nil then
    target_path = result.success[1]:get()
  end

  self._loader:load(nil, target_path)
end

M.write = function(bufnr)
  local creator = persist.creators[bufnr]
  if creator == nil then
    return
  end
  creator:write()
end

return M
