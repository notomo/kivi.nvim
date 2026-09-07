local Context = require("kivi.core.context")
local controller = require("kivi.controller")

local M = {}

function M.open(raw_opts)
  --- @async
  --- @return nil
  local open = function()
    local ok, err = pcall(controller.open, raw_opts)
    if not ok then
      require("kivi.lib.message").warn(err)
    end
  end
  return vim.async.run(open)
end

--- @param path string
function M.navigate(path)
  local ctx = Context.get()
  if type(ctx) == "string" then
    local err = ctx
    error(require("kivi.lib.message").wrap(err), 0)
  end

  --- @async
  --- @return nil
  local navigate = function()
    local ok, err = pcall(controller.navigate, ctx, path)
    if not ok then
      require("kivi.lib.message").warn(err)
    end
  end
  return vim.async.run(navigate)
end

function M.execute(action_name, opts, action_opts)
  local range = require("kivi.vendor.misclib.visual_mode").row_range()
    or { first = vim.fn.line("."), last = vim.fn.line(".") }
  opts = opts or {}
  action_opts = action_opts or {}
  --- @async
  --- @return nil
  local execute = function()
    local ok, err = pcall(controller.execute, action_name, range, opts, action_opts)
    if not ok then
      require("kivi.lib.message").warn(err)
    end
  end
  return vim.async.run(execute)
end

function M.is_parent()
  local ctx = Context.get()
  if type(ctx) == "string" then
    local err = ctx
    error(require("kivi.lib.message").wrap(err), 0)
  end

  local nodes = ctx.ui:selected_nodes()
  local kind = nodes:kind()
  if type(kind) == "string" then
    local err = kind
    error(require("kivi.lib.message").wrap(err), 0)
  end

  return kind.is_parent == true
end

function M.get()
  local ctx = Context.get()
  if type(ctx) == "string" then
    local err = ctx
    error(require("kivi.lib.message").wrap(err), 0)
  end
  return ctx.ui:selected_nodes()
end

-- for test
function M.promise()
  local tasks = {}
  vim.list_extend(tasks, require("kivi.view").promises())
  vim.list_extend(tasks, require("kivi.view.renamer").promises())
  vim.list_extend(tasks, require("kivi.view.creator").promises())
  --- @async
  --- @return nil
  local wait_all = function()
    for _, task in ipairs(tasks) do
      vim.async.pawait(task)
    end
  end
  return vim.async.run(wait_all)
end

return M
