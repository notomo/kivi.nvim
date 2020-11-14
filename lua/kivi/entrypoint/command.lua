local wraplib = require("kivi/lib/wrap")
local messagelib = require("kivi/lib/message")
local cmdparse = require("kivi/lib/cmdparse")
local Loader = require("kivi/core/loader").Loader
local Starter = require("kivi/core/starter").Starter

local M = {}

M.start_by_excmd = function(has_range, raw_range, raw_args)
  local source_name, opts, _, parse_err = cmdparse.args(raw_args, {})
  if parse_err ~= nil then
    return nil, messagelib.error(parse_err)
  end

  local range = nil
  if has_range ~= 0 then
    range = {first = raw_range[1], last = raw_range[2]}
  end
  opts.range = range

  local result, err = wraplib.traceback(function()
    return Starter.new():open(source_name, opts)
  end)
  if err ~= nil then
    return nil, messagelib.error(err)
  end
  return result, nil
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
    return Starter.new():execute(action_name, range, action_opts)
  end)
  if err ~= nil then
    return nil, messagelib.error(err)
  end
  return result, nil
end

M.read = function(bufnr)
  return Loader.new(bufnr):load()
end

vim.api.nvim_command("doautocmd User KiviSourceLoad")

return M
