local filelib = require("kivi.lib.file")
local Promise = require("kivi.vendor.promise")
local stringbuf = require("string.buffer")

local M = {}

local collect
collect = function(target_dir, opts_expanded)
  target_dir = filelib.adjust(target_dir)

  local promise, resolve, reject = Promise.with_resolvers()
  local sender
  sender = vim.uv.new_async(function(v)
    local decoded = stringbuf.decode(v) or { error = "decoded invalid" }
    if decoded.error then
      reject(decoded.error)
    else
      resolve(decoded.root, decoded.expand_indicies)
    end
    assert(sender)
    sender:close()
  end)
  assert(sender)

  ---@diagnostic disable-next-line: param-type-mismatch
  vim.uv.new_thread(function(async, dir, _expanded)
    ---@diagnostic disable-next-line: redefined-local
    local stringbuf = require("string.buffer")
    local f = function()
      local entries = require("kivi.lib.file").entries(dir)
      if type(entries) == "string" then
        local err = entries
        return async:send(stringbuf.encode({ error = err }))
      end

      local expanded = stringbuf.decode(_expanded) or {}

      local pathlib = require("kivi.lib.path")
      local root = {
        value = pathlib.slash(pathlib.tail(dir)),
        path = dir,
        kind_name = "directory",
        children = {},
      }
      local expand_indicies = {}
      for i, entry in ipairs(entries) do
        local kind_name = "file"
        if entry.is_directory then
          kind_name = "directory"
        end

        local path = entry.path
        local child = {
          value = entry.name,
          path = path,
          kind_name = kind_name,
          is_broken = entry.is_broken_link,
          real_path = entry.real_path,
        }
        if child.kind_name == "directory" and expanded[child.path] then
          table.insert(expand_indicies, i)
        end
        table.insert(root.children, child)
      end

      async:send(stringbuf.encode({ expand_indicies = expand_indicies, root = root }))
    end
    local traceback = debug.traceback
    ---@cast traceback function
    local ok, err = xpcall(f, traceback)
    if not ok then
      error(err)
    end
    ---@diagnostic disable-next-line: param-type-mismatch
  end, sender, target_dir, stringbuf.encode(opts_expanded))

  return promise
    :next(function(root, expand_indicies)
      local promises = {}
      for _, i in ipairs(expand_indicies) do
        local child = root.children[i]
        table.insert(
          promises,
          collect(child.path, opts_expanded):next(function(result, err)
            if err then
              -- HACK
              return
            end
            root.children[i].children = result.children
          end)
        )
      end
      return Promise.all(promises):next(function()
        return root
      end)
    end)
    :catch(function(err)
      if err:match([[can't open]]) then
        return nil, err
      end
      return require("kivi.vendor.promise").reject(err)
    end)
end

function M.collect(opts)
  local dir = filelib.adjust(opts.path)
  if not filelib.is_dir(dir) then
    return Promise.reject("does not exist: " .. dir)
  end
  return collect(dir, opts.expanded)
end

local highlightlib = require("kivi.vendor.misclib.highlight")
highlightlib.link("KiviDirectory", "String")
highlightlib.link("KiviBrokenLink", "WarningMsg")
highlightlib.define("KiviDirectoryOpen", {
  fg = vim.api.nvim_get_hl(0, { name = "KiviDirectory" }).fg,
  bold = true,
})

local highlight_opts = {
  priority = vim.hl.priorities.user - 1,
}

function M.highlight_one(decorator, row, node, opts)
  if node.kind_name == "directory" then
    decorator:highlight_line("KiviDirectory", row, highlight_opts)
  end
  if node.kind_name == "directory" and opts.expanded[node.path] then
    decorator:highlight_line("KiviDirectoryOpen", row, highlight_opts)
  end
  if node.is_broken then
    decorator:highlight_line("KiviBrokenLink", row, highlight_opts)
  end
  if node.real_path then
    decorator:add_virtual_text(row, 0, { { "-> " .. node.real_path, "Comment" } })
  end
  if node.is_git_ignored then
    decorator:highlight_line("Comment", row, highlight_opts)
    decorator:add_virtual_text(row, 0, { { "[X]", "Comment" } })
  end
end

function M.init_path(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local path = vim.api.nvim_buf_get_name(bufnr)
  if not filelib.readable(path) then
    return
  end

  return filelib.adjust(path)
end

local watchers = {}

M.debounce_ms = 500

--- @param hook_ctx KiviSourceHookContext
function M.hook(hook_ctx)
  local nodes = hook_ctx.nodes
  local path = nodes.root_path
  if not filelib.exists(path) then
    return
  end

  local bufnr = hook_ctx.bufnr
  local old_watcher = watchers[bufnr]
  if old_watcher then
    old_watcher:stop()
  end

  local watcher = vim.uv.new_fs_event()
  assert(watcher, "failed to create fs event")
  watchers[bufnr] = watcher
  watcher:start(
    path,
    {},
    require("kivi.vendor.misclib.debounce").wrap(M.debounce_ms, function()
      watcher:stop()
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(bufnr) then
          return
        end
        vim.api.nvim_buf_call(bufnr, function()
          vim.cmd.edit()
        end)
      end)
    end)
  )

  local window_id = vim.fn.win_findbuf(bufnr)[1]
  if window_id then
    vim.api.nvim_win_call(window_id, function()
      vim.fn.chdir(path, "window")
    end)
    require("kivi.lib.git_ignore").apply(path, nodes, window_id, hook_ctx.reload)
  end

  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_create_autocmd({ "BufWipeout" }, {
      group = vim.api.nvim_create_augroup("kivi.file.reload_buffer_" .. tostring(bufnr), {}),
      buffer = bufnr,
      callback = function()
        watchers[bufnr] = nil
        watcher:stop()
        watcher:close()
      end,
    })
  end
end

M.kind_name = "file"
M.opts = {}

return M
