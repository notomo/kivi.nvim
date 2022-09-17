local vim = vim

local M = {}

function M.default(name, attributes)
  local new_attributes = {}
  for key, value in pairs(attributes) do
    if type(value) == "table" then
      local hl_group, attribute = unpack(value)
      local hl = vim.api.nvim_get_hl_by_name(hl_group, true)
      new_attributes[key] = hl[attribute]
    else
      new_attributes[key] = value
    end
  end
  new_attributes.default = true
  vim.api.nvim_set_hl(0, name, new_attributes)
end

return M
