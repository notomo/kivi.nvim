local Context = require("kivi.core.context")
local controller = require("kivi.controller")

local M = {}

function M.open(raw_opts)
  return controller
    .open(raw_opts)
    :next(function(_, e)
      if e then
        require("kivi.vendor.misclib.message").warn(e)
        return
      end
    end)
    :catch(function(e)
      require("kivi.vendor.misclib.message").warn(e)
    end)
end

function M.navigate(path, source_setup_opts)
  vim.validate({ path = { path, "string" }, source_setup_opts = { source_setup_opts, "table", true } })
  source_setup_opts = source_setup_opts or {}

  local ctx, err = Context.get()
  if err then
    return require("kivi.vendor.promise").reject(err)
  end

  return controller
    .navigate(ctx, path, source_setup_opts)
    :next(function(_, e)
      if e then
        require("kivi.vendor.misclib.message").warn(e)
        return
      end
    end)
    :catch(function(e)
      require("kivi.vendor.misclib.message").warn(e)
    end)
end

function M.execute(action_name, opts, action_opts)
  vim.validate({
    action_name = { action_name, "string" },
    opts = { opts, "table", true },
    action_opts = { action_opts, "table", true },
  })
  local range = require("kivi.vendor.misclib.visual_mode").row_range()
    or { first = vim.fn.line("."), last = vim.fn.line(".") }
  opts = opts or {}
  action_opts = action_opts or {}
  return controller
    .execute(action_name, range, opts, action_opts)
    :next(function(_, e)
      if e then
        require("kivi.vendor.misclib.message").warn(e)
        return
      end
    end)
    :catch(function(err)
      require("kivi.vendor.misclib.message").warn(err)
    end)
end

function M.is_parent()
  local ctx, err = Context.get()
  if err then
    require("kivi.vendor.misclib.message").error(err)
  end

  local nodes = ctx.ui:selected_nodes()
  local kind, kind_err = nodes:kind()
  if kind_err then
    require("kivi.vendor.misclib.message").error(kind_err)
  end

  return kind.is_parent == true
end

function M.get()
  local ctx, err = Context.get()
  if err then
    require("kivi.vendor.misclib.message").error(err)
  end
  return ctx.ui:selected_nodes()
end

-- for test
function M.promise()
  local promises = {}
  vim.list_extend(promises, require("kivi.view").promises())
  vim.list_extend(promises, require("kivi.view.renamer").promises())
  vim.list_extend(promises, require("kivi.view.creator").promises())
  return require("kivi.vendor.promise").all(promises)
end

return M
