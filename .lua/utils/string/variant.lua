local color <const> = require("musictk.lib.ansicolors")

local new_cache <const> = function ()
  local cache = {}

  local add = function (bool, base, variant)
    if bool then
      cache[base] = variant
    end
  end

  local __call = function (_, base)
    local variant = cache[base]
    if not variant then
      return base
    end
    return color(variant)
  end

  return setmetatable({
    add = add
  }, {
    __call = __call
  })
end

local v <const> = new_cache()

return v