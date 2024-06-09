local messagelib = require("kivi.lib.message")
local cursorlib = require("kivi.lib.cursor")
local pathlib = require("kivi.lib.path")

local ns = vim.api.nvim_create_namespace("kivi-renamer")

local Renamer = {}

local _promise = nil

function Renamer.open(kind, tree_bufnr, base_node, rename_items, has_cut)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].buftype = "acwrite"
  vim.api.nvim_buf_set_name(bufnr, "kivi://" .. bufnr .. "/kivi-renamer")

  local froms = {}
  for i, item in ipairs(rename_items) do
    froms[i] = item.from
  end

  local state = {
    froms = froms,
    has_cut = has_cut,
    lines = vim
      .iter(rename_items)
      :map(function(item)
        local path = item.to or item.from
        return pathlib.relative(base_node.path, path)
      end)
      :totable(),
  }

  Renamer._read(bufnr, base_node.path, state.lines)
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

  vim.api.nvim_create_autocmd({ "BufReadCmd" }, {
    buffer = bufnr,
    nested = true,
    callback = function()
      Renamer._read(bufnr, base_node.path, state.lines)
    end,
  })
  vim.api.nvim_create_autocmd({ "BufWriteCmd" }, {
    buffer = bufnr,
    nested = true,
    callback = function()
      local result = Renamer._write(bufnr, base_node.path, kind, state.has_cut, state.lines, state.froms)
      state = result.next_state
      _promise = require("kivi.core.loader").reload(tree_bufnr, result.cursor_line_path)
    end,
  })
  vim.api.nvim_exec_autocmds("BufRead", { modeline = false }) -- HACK?
end

function Renamer._write(bufnr, base_node_path, kind, has_cut, state_lines, froms)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 1, -1, true)
  local items = vim
    .iter(lines)
    :enumerate()
    :map(function(i, line)
      local original_line = state_lines[i]
      if original_line == nil then
        return
      end
      if line == original_line then
        return
      end
      return {
        from = froms[i] or pathlib.join(base_node_path, original_line),
        to = pathlib.join(base_node_path, line),
      }
    end)
    :totable()

  local success = {}
  local already_exists = {}
  vim.iter(items):enumerate():each(function(i, item)
    if kind.exists(item.to) then
      table.insert(already_exists, item)
      return
    end

    if has_cut then
      kind.rename(item.from, item.to)
    else
      kind.copy(item.from, item.to)
    end

    success[i] = item
  end)

  local last_index = 0
  local next_lines = vim.deepcopy(state_lines)
  local next_froms = vim.deepcopy(froms)
  for i in pairs(success) do
    local line = lines[i]
    local marks = vim.api.nvim_buf_get_extmarks(bufnr, ns, { i, 0 }, { i, -1 }, { details = true })
    if marks[1] then
      local id = marks[1][1]
      vim.api.nvim_buf_set_extmark(bufnr, ns, i, #line, {
        virt_text = { { "<- " .. line, "Comment" } },
        id = id,
      })
    end
    next_lines[i] = line
    next_froms[i] = nil
    last_index = i
  end

  local cursor_line_path = nil
  if success[last_index] ~= nil then
    cursor_line_path = success[last_index].to
  end

  local next_has_cut = has_cut
  if #already_exists == 0 then
    vim.bo[bufnr].modified = false
    next_has_cut = true
  else
    messagelib.warn(
      "already exists:",
      vim
        .iter(already_exists)
        :map(function(item)
          return item.to
        end)
        :totable()
    )
  end

  return {
    cursor_line_path = cursor_line_path,
    next_state = {
      has_cut = next_has_cut,
      lines = next_lines,
      froms = next_froms,
    },
  }
end

function Renamer._read(bufnr, base_node_path, lines)
  vim.api.nvim_buf_set_lines(bufnr, 0, 0, true, { "" })
  vim.api.nvim_buf_set_lines(bufnr, 1, -1, true, lines)

  vim.api.nvim_buf_set_extmark(bufnr, ns, 0, 0, {
    virt_text = { { base_node_path, "Comment" } },
  })
  for i, line in ipairs(lines) do
    vim.api.nvim_buf_set_extmark(bufnr, ns, i, #line, {
      virt_text = { { "<- " .. line, "Comment" } },
    })
  end
end

-- for test
function Renamer.promises()
  if _promise then
    local promise = _promise
    _promise = nil
    return { promise }
  end
  return {}
end

return Renamer
