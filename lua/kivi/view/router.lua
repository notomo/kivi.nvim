local Loader = require("kivi.core.loader").Loader
local Renamer = require("kivi.view.renamer").Renamer
local Creator = require("kivi.view.creator").Creator

local M = {}

local Router = {}
Router.__index = Router
M.Router = Router

function Router.read(bufnr)
  local path = Router._path(bufnr)
  if not path then
    return nil
  end

  if path:match("/kivi$") then
    return Loader.new(bufnr):reload()
  elseif path:match("/kivi%-renamer$") then
    return Renamer.read_from(bufnr)
  end
end

function Router.write(bufnr)
  local path = Router._path(bufnr)
  if not path then
    return nil
  end

  if path:match("/kivi%-creator$") then
    return Creator.write_from(bufnr)
  elseif path:match("/kivi%-renamer$") then
    return Renamer.write_from(bufnr)
  end
end

function Router._path(bufnr)
  vim.validate({bufnr = {bufnr, "number"}})
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end
  return vim.api.nvim_buf_get_name(bufnr)
end

return M
