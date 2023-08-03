local configuration = {}

local register = function (key, val)
end

local set = function (key, val)
end

local get = function (key)
  return configuration[key]
end

return {
  register = register,
  set = set,
  get = get,
}