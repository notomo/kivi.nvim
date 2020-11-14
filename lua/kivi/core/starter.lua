local custom = require("kivi/custom")
local repository = require("kivi/core/repository")
local Source = require("kivi/core/source").Source
local History = require("kivi/core/history").History
local Clipboard = require("kivi/core/clipboard").Clipboard
local Loader = require("kivi/core/loader").Loader
local Executor = require("kivi/core/executor").Executor
local Kind = require("kivi/core/kind").Kind
local PendingUI = require("kivi/view/ui").PendingUI
local Renamer = require("kivi/view/renamer").Renamer

local M = {}

local Starter = {}
Starter.__index = Starter
M.Starter = Starter

local default_opts = {path = ".", layout = "no", back = false}

function Starter.new(source_name)
  vim.validate({source_name = {source_name, "string", true}})
  local tbl = {_source_name = source_name}
  return setmetatable(tbl, Starter)
end

function Starter.open(self, source_name, opts)
  opts = vim.tbl_extend("force", default_opts, custom.opts, opts or {})

  local source, err = Source.new(source_name or self._source_name)
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

  return Loader.new(ui.bufnr):load()
end

function Starter.execute(self, action_name, range, action_opts)
  local ctx, err = repository.get_from_path()
  if err ~= nil then
    return nil, err
  end

  local nodes = ctx.ui:selected_nodes(action_name, range)
  ctx.ui:reset_selections(action_name)
  return Executor.new(self, ctx.ui, ctx.source):execute(ctx, nodes, action_name, action_opts)
end

function Starter.rename(self, base_node, rename_items, has_cut)
  local ctx, err = repository.get_from_path()
  if err ~= nil then
    return nil, err
  end

  local kind, kind_err = Kind.new(self, ctx.source.kind_name)
  if err ~= nil then
    return nil, kind_err
  end

  local loader = Loader.new(ctx.ui.bufnr)
  Renamer.open(kind, loader, base_node, rename_items, has_cut)
end

return M
