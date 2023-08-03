local need = require("utils.need")
local abs = math.abs
local words = {}

---@param singular_form string
---@param plural_form string
return function (singular_form, plural_form)
  if words[singular_form] then
    return words[singular_form]
  end

  ---@param count string
  ---@return string
  words[singular_form] = need(function (count)
    return abs(count) ~= 1 and plural_form or singular_form
  end, "number")

  return words[singular_form]
end