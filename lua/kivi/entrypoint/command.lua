local wraplib = require("kivi/lib/wrap")
local messagelib = require("kivi/lib/message")
local custom = require("kivi/custom")
local cmdparse = require("kivi/lib/cmdparse")
local Notifier = require("kivi/lib/notifier").Notifier
local repository = require("kivi/core/repository")
local Source = require("kivi/core/source").Source
local Collector = require("kivi/core/collector").Collector
local Executor = require("kivi/core/executor").Executor
local History = require("kivi/core/history").History
local Clipboard = require("kivi/core/clipboard").Clipboard
local PendingUI = require("kivi/view/ui").PendingUI
local Renamer = require("kivi/view/renamer").Renamer

local M = {}

local start_default_opts = {path = ".", layout = "no", back = false}

local global_notifier = Notifier.new()
global_notifier:on("start_path", function(source_name, source_opts, opts)
  M._start(source_name, source_opts, vim.tbl_extend("force", start_default_opts, opts))
end)
global_notifier:on("reload_path", function(bufnr)
  M.read(bufnr)
end)
global_notifier:on("start_renamer", function(base_node, rename_items, has_cut)
  M._start_renamer(base_node, rename_items, has_cut)
end)

M.start_by_excmd = function(has_range, raw_range, raw_args)
  local source_name, opts, ex_opts, parse_err = cmdparse.args(raw_args, vim.tbl_extend("force", start_default_opts, custom.opts))
  if parse_err ~= nil then
    return nil, messagelib.error(parse_err)
  end

  local range = nil
  if has_range ~= 0 then
    range = {first = raw_range[1], last = raw_range[2]}
  end
  opts.range = range

  local source_opts = ex_opts.x or {}
  local result, err = wraplib.traceback(function()
    return M._start(source_name, source_opts, opts)
  end)
  if err ~= nil then
    return nil, messagelib.error(err)
  end
  return result, nil
end

M._start = function(source_name, source_opts, opts)
  local source, err = Source.new(source_name, source_opts)
  if err ~= nil then
    return nil, err
  end

  local ui, key = PendingUI.open(source, opts.layout)
  local ctx = {
    ui = ui,
    source = source,
    opts = opts,
    history = History.new(key),
    clipboard = Clipboard.new(source.name),
  }
  repository.set(key, ctx)

  return M.read(ui.bufnr)
end

M.execute = function(has_range, raw_range, raw_args)
  local action_name, _, ex_opts, parse_err = cmdparse.args(raw_args, {})
  if parse_err ~= nil then
    return nil, messagelib.error(parse_err)
  end

  local range = nil
  if has_range ~= 0 then
    range = {first = raw_range[1], last = raw_range[2]}
  end

  local action_opts = ex_opts.x or {}
  local result, err = wraplib.traceback(function()
    return M._execute(action_name, range, action_opts)
  end)
  if err ~= nil then
    return nil, messagelib.error(err)
  end
  return result, nil
end

M._execute = function(action_name, range, action_opts)
  local ctx, err = repository.get_from_path()
  if err ~= nil then
    return nil, "not found state: " .. err
  end

  local nodes = ctx.ui:selected_nodes(action_name, range)
  ctx.ui:reset_selections(action_name)
  return Executor.new(global_notifier, ctx.ui, ctx.source):execute(ctx, nodes, action_name, action_opts)
end

M.read = function(bufnr)
  local ctx, err = repository.get_from_path(bufnr)
  if err ~= nil then
    return nil, err
  end
  if ctx.ui == nil then
    return nil, nil
  end

  local result, start_err = Collector.new(ctx.source):start(ctx.opts)
  if start_err ~= nil then
    return nil, start_err
  end

  local root, ok = result:get()
  if ok then
    ctx.history:add(root.path, ctx.opts.back)
    ctx.ui = ctx.ui:redraw(root, ctx.source, ctx.history)
    ctx.history:set(root.path)
    ctx.source:hook(root.path)
    -- TODO: else job
  end

  return result, nil
end

M._start_renamer = function(base_node, rename_items, has_cut)
  local ctx, err = repository.get_from_path()
  if err ~= nil then
    return nil, "not found state: " .. err
  end

  local executor = Executor.new(global_notifier, ctx.ui, ctx.source)
  Renamer.open(executor, base_node, rename_items, has_cut)
end

vim.api.nvim_command("doautocmd User KiviSourceLoad")

return M
