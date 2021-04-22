local M = {}

function M.group_by(list, make_key)
  local prev = nil
  local groups = {}
  for _, element in ipairs(list) do
    local key = make_key(element)
    if key == prev then
      table.insert(groups[#groups][2], element)
    else
      table.insert(groups, {key, {element}})
    end
    prev = key
  end
  return groups
end

return M
