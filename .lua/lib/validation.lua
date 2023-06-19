---@type {string:fun(input: any): boolean, string?}
local validators = {}
do
  local const = require("constants")

  validators.email = function (input)
    if not type(input) == "string" then
      return false, "email must be a string"
    end

    if not const.re.email:search(input) then
      return false, "invalid email"
    end

    return true
  end

  validators.uuid = function (input)
    if not type(input) == "string" then
      return false, "uuid must be a string"
    end

    if not const.re.uuid:search(input) then
      return false, "invalid uuid"
    end

    return true
  end

  validators.password = function (input)
    if not type(input) == "string" then
      return false, "password must be a string"
    end

    return true
  end

  validators.username = function (input)
    if not type(input) == "string" then
      return false, "password must be a string"
    end

    return true
  end
end

---@param kind
---|"email"
---|"uuid"
---|"password"
---|"username"
---@param input any
---@return boolean
---@return string?
local validate = function (kind, input)
  local check = validators[assert(kind, "please provide a type of validator")]
  if not check then
    return false, "cannot validate, none defined for " .. kind
  end
  return check(input)
end

return {
  validate = validate
}