local color = require("lib.ansicolors")
local need = require("lib.need")
local fmt = string.format

---@param msg string
---@param ... any
local _info = function (msg, ...)
  Log(kLogInfo, color(fmt("(%s) " .. msg, "%{blue}forum%{reset}", ...)))
end

local _error = function (msg, ...)
  Log(kLogError, color(fmt("(%s) " .. msg, "%{red}forum%{reset}", ...)))
end

local _warn = function (msg, ...)
  Log(kLogWarn, color(fmt("(%s) " .. msg, "%{yellow}forum%{reset}", ...)))
end

local _debug = function (msg, ...)
  Log(kLogDebug, color(fmt("(%s) " .. msg, "%{yellow}forum%{reset}", ...)))
end

local _fatal = function (msg, ...)
  Log(kLogFatal, color(fmt("(%s) " .. msg, "%{red}forum%{reset}", ...)))
end

return {
  warn = need(_warn, "string"),
  info = need(_info, "string"),
  error = need(_error, "string"),
  debug = need(_debug, "string"),
  fatal = need(_fatal, "string"),
}