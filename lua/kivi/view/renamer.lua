local repository = require("kivi.lib.repository").Repository.new("renamer")
local messagelib = require("kivi.lib.message")
local cursorlib = require("kivi.lib.cursor")

local ns = vim.api.nvim_create_namespace("kivi-renamer")

local Renamer = {}
Renamer.__index = Renamer

function Renamer.open(kind, loader, base_node, rename_items, has_cut)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].buftype = "acwrite"
  vim.api.nvim_buf_set_name(bufnr, "kivi://" .. bufnr .. "/kivi-renamer")

  local froms = {}
  for i, item in ipairs(rename_items) do
    froms[i] = item.from
  end

  local tbl = {
    _bufnr = bufnr,
    _lines = vim.tbl_map(function(item)
      return base_node.path:relative(item.to or item.from)
    end, rename_items),
    _froms = froms,
    _base_node = base_node,
    _has_cut = has_cut,
    _kind = kind,
    _loader = loader,
  }
  local renamer = setmetatable(tbl, Renamer)
  renamer:read()
  vim.bo[bufnr].modified = false

  local width = 75
  local height = #rename_items
  local window_id = vim.api.nvim_open_win(bufnr, true, {
    width = width,
    height = height + 1,
    relative = "editor",
    row = math.floor(vim.o.lines / 2) - math.floor((height + 2) / 2) - 2,
    col = math.floor(vim.o.columns / 2) - math.floor(width / 2),
    anchor = "NW",
    focusable = true,
    external = false,
    style = "minimal",
    border = { { " ", "NormalFloat" } },
  })
  cursorlib.set_row(2, window_id, bufnr)
  repository:set(bufnr, renamer)

  vim.api.nvim_create_autocmd({ "BufReadCmd" }, {
    buffer = bufnr,
    nested = true,
    callback = function()
      renamer:read()
    end,
  })
  vim.api.nvim_create_autocmd({ "BufWriteCmd" }, {
    buffer = bufnr,
    nested = true,
    callback = function()
      renamer:write()
    end,
  })
  vim.api.nvim_create_autocmd({ "BufWipeout" }, {
    buffer = bufnr,
    callback = function()
      repository:delete(bufnr)
    end,
  })
  vim.api.nvim_exec_autocmds("BufRead", { modeline = false }) -- HACK?
end

function Renamer.write(self)
  local lines = vim.api.nvim_buf_get_lines(self._bufnr, 1, -1, true)
  local items = {}
  for i, line in ipairs(lines) do
    local original_line = self._lines[i]
    if original_line == nil then
      break
    end
    if line == original_line then
      goto continue
    end
    table.insert(items, {
      from = self._froms[i] or self._base_node.path:join(original_line),
      to = self._base_node.path:join(line),
    })
    ::continue::
  end

  local success = {}
  local already_exists = {}
  for i, item in ipairs(items) do
    if item.to:exists() then
      table.insert(already_exists, item)
      goto continue
    end

    if self._has_cut then
      self._kind:rename(item.from, item.to)
    else
      self._kind:copy(item.from, item.to)
    end

    success[i] = item
    ::continue::
  end

  local last_index = 0
  for i in pairs(success) do
    local line = lines[i]
    local marks = vim.api.nvim_buf_get_extmarks(self._bufnr, ns, { i, 0 }, { i, -1 }, { details = true })
    if marks[1] then
      local id = marks[1][1]
      vim.api.nvim_buf_set_extmark(self._bufnr, ns, i, #line, {
        virt_text = { { "<- " .. line, "Comment" } },
        id = id,
      })
    end
    self._lines[i] = line
    self._froms[i] = nil
    last_index = i
  end

  local cursor_line_path = nil
  if success[last_index] ~= nil then
    cursor_line_path = success[last_index].to:get()
  end

  if #already_exists == 0 then
    vim.bo[self._bufnr].modified = false
    self._has_cut = true
  else
    messagelib.warn(
      "already exists:",
      vim.tbl_map(function(item)
        return item.to:get()
      end, already_exists)
    )
  end

  self._loader:reload(cursor_line_path)
end

function Renamer.read(self)
  vim.api.nvim_buf_set_lines(self._bufnr, 0, 0, true, { "" })
  vim.api.nvim_buf_set_lines(self._bufnr, 1, -1, true, self._lines)

  vim.api.nvim_buf_set_extmark(self._bufnr, ns, 0, 0, {
    virt_text = { { self._base_node.path:get(), "Comment" } },
  })
  for i, line in ipairs(self._lines) do
    vim.api.nvim_buf_set_extmark(self._bufnr, ns, i, #line, {
      virt_text = { { "<- " .. line, "Comment" } },
    })
  end
end

return Renamer
