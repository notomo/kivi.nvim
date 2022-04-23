local Context = require("kivi.core.context")
local Controller = require("kivi.controller")

local ShowError = require("kivi.vendor.misclib.error_handler").for_show_error()
local ReturnValue = require("kivi.vendor.misclib.error_handler").for_return_value()

function ReturnValue.open(raw_opts)
  vim.validate({ raw_opts = { raw_opts, "table", true } })
  raw_opts = raw_opts or {}
  return Controller.new():open(raw_opts)
end

function ReturnValue.navigate(path, source_setup_opts)
  vim.validate({ path = { path, "string" }, source_setup_opts = { source_setup_opts, "table", true } })
  source_setup_opts = source_setup_opts or {}

  local ctx, err = Context.get()
  if err ~= nil then
    return nil, err
  end

  return Controller.new():navigate(ctx, path, source_setup_opts)
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
  return Controller.new():execute(action_name, range, opts, action_opts)
end

function ShowError.read(bufnr)
  return require("kivi.core.loader").new(bufnr):reload()
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

return vim.tbl_extend("force", ShowError:methods(), ReturnValue:methods())
