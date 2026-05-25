local M = {}

function M.emit_renamed(renames)
  if #renames == 0 then
    return
  end
  vim.api.nvim_exec_autocmds("User", {
    pattern = "KiviRenamed",
    data = { renames = renames },
  })
end

return M
