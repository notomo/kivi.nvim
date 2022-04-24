local Context = require("kivi.core.context")
local Controller = require("kivi.controller")

local ShowError = require("kivi.vendor.misclib.error_handler").for_show_error()
local ReturnValue = require("kivi.vendor.misclib.error_handler").for_return_value()

function ReturnValue.open(raw_opts)
  return Controller.new():open(raw_opts):catch(function(e)
    require("kivi.vendor.misclib.message").warn(e)
  end)
end

function ReturnValue.navigate(path, source_setup_opts)
  vim.validate({ path = { path, "string" }, source_setup_opts = { source_setup_opts, "table", true } })
  source_setup_opts = source_setup_opts or {}

  local ctx, err = Context.get()
  if err ~= nil then
    return require("kivi.vendor.promise").reject(err)
  end

  return Controller.new():navigate(ctx, path, source_setup_opts):catch(function(e)
    require("kivi.vendor.misclib.message").warn(e)
  end)
end

function ReturnValue.execute(action_name, opts, action_opts)
  vim.validate({
    action_name = { action_name, "string" },
    opts = { opts, "table", true },
    action_opts = { action_opts, "table", true },
  })
  local range = require("kivi.vendor.misclib.visual_mode").row_range()
    or { first = vim.fn.line("."), last = vim.fn.line(".") }
  opts = opts or {}
  action_opts = action_opts or {}
  return Controller.new():execute(action_name, range, opts, action_opts):catch(function(err)
    require("kivi.vendor.misclib.message").warn(err)
  end)
end

function ReturnValue.is_parent()
  local ctx, err = Context.get()
  if err ~= nil then
    return false, err
  end

  local nodes = ctx.ui:selected_nodes()
  local kind, kind_err = nodes:kind()
  if kind_err ~= nil then
    return false, kind_err
  end

  return kind.is_parent == true, nil
end

-- for test
function ReturnValue.promise()
  local promises = {}
  vim.list_extend(promises, require("kivi.view").promises())
  vim.list_extend(promises, require("kivi.view.renamer").promises())
  vim.list_extend(promises, require("kivi.view.creator").promises())
  return require("kivi.vendor.promise").all(promises)
end

return vim.tbl_extend("force", ShowError:methods(), ReturnValue:methods())
