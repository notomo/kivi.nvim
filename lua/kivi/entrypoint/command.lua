local uis = require("kivi/view/ui")
local collector_core = require("kivi/core/collector")
local wraplib = require("kivi/lib/wrap")
local messagelib = require("kivi/lib/message")
local custom = require("kivi/custom")
local cmdparse = require("kivi/lib/cmdparse")
local repository = require("kivi/core/repository")
local executor_core = require("kivi/core/executor")
local notifiers = require("kivi/lib/notifier")

local M = {}

local global_notifier = notifiers.new()
global_notifier:on("open_path", function(source_name, source_opts, opts)
  M._start(source_name, source_opts, opts)
end)

local start_default_opts = {path = ".", layout = "vertical"}

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
  source_name = source_name or "file"
  local ui, key = uis.open(source_name, opts.layout)

  local ctx = {ui = ui, source_name = source_name, source_opts = source_opts, opts = opts}
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

  if action_name == nil then
    action_name = "default"
  end

  local executor = executor_core.create(global_notifier, ctx.ui, ctx.source_name, {}, nil)
  local node_groups = ctx.ui:node_groups(action_name, range)
  for _, node_group in ipairs(node_groups) do
    local kind_name, nodes = unpack(node_group)
    local add_err = executor:add(action_name, kind_name, nodes, action_opts)
    if add_err ~= nil then
      return nil, add_err
    end
  end

  return executor:batch(ctx)
end

M.read = function(bufnr)
  local ctx, err = repository.get_from_path(bufnr)
  if err ~= nil then
    return nil, err
  end
  if ctx.ui == nil then
    ctx.ui = uis.from_current()
    -- TODO: ctx.source_name = source_name
    ctx.source_opts = {}
    ctx.opts = vim.deepcopy(start_default_opts)
  end

  local collector, create_err = collector_core.create(ctx.source_name, ctx.source_opts)
  if create_err ~= nil then
    return nil, create_err
  end

  local result, start_err = collector:start(ctx.opts)
  if start_err ~= nil then
    return nil, start_err
  end

  ctx.ui = ctx.ui:redraw(bufnr, result, ctx.opts)

  return result, nil
end

vim.api.nvim_command("doautocmd User KiviSourceLoad")

return M
