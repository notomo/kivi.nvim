local messagelib = require("kivi.lib.message")
local windowlib = require("kivi.lib.window")
local pathlib = require("kivi.lib.path")

local Creator = {}

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

  vim.cmd.startinsert()

  vim.api.nvim_create_autocmd({ "BufWriteCmd" }, {
    buffer = bufnr,
    nested = true,
    callback = function()
      local result = Creator._write(bufnr, window_id, base_node.path, kind)
      _promise = require("kivi.core.loader").reload(tree_bufnr, result.cursor_line_path, result.expanded)
    end,
  })
end

function Creator._write(bufnr, window_id, base_node_path, kind)
  local paths = vim
    .iter(vim.api.nvim_buf_get_lines(bufnr, 0, -1, true))
    :filter(function(line)
      return line ~= ""
    end)
    :map(function(line)
      return pathlib.join(base_node_path, line)
    end)
    :totable()

  local success = {}
  local errors = {}
  vim.iter(paths):enumerate():each(function(i, path)
    if kind.exists(path) then
      table.insert(errors, { path = path, msg = "already exists: " .. path })
      return
    end

    local err = kind.create(path)
    if err then
      table.insert(errors, { path = path, msg = err })
      return
    end

    success[i] = path
  end)

  vim.api.nvim_buf_set_lines(
    bufnr,
    0,
    -1,
    false,
    vim
      .iter(errors)
      :map(function(e)
        return pathlib.relative(base_node_path, e.path)
      end)
      :totable()
  )

  if #errors == 0 then
    vim.bo[bufnr].modified = false
    windowlib.close(window_id)
  else
    for _, e in ipairs(errors) do
      messagelib.warn(e.msg)
    end
  end

  local last_index = 0
  local expanded = {}
  for i, path in pairs(success) do
    for _, p in ipairs(pathlib.between(path, base_node_path)) do
      expanded[p] = true
    end
    last_index = i
  end

  local cursor_line_path = nil
  if success[last_index] ~= nil then
    cursor_line_path = success[last_index]
  end

  return {
    expanded = expanded,
    cursor_line_path = cursor_line_path,
  }
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
