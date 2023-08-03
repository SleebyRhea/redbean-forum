local log = require("utils.log")
local catch_json, log_err, catch
local need = require("api.need")
local json_response = require("utils.data").json_response

do
  local traceback = debug.traceback
  log_err = function ()
    log.error(traceback())
  end
end


do
  local check_ok_json = function (ok, ...)
    if not ok then
      return json_response(500, "internal server error")
    end
    return ...
  end

  catch_json = function (execute)
    return function (...)
      return check_ok_json(xpcall(execute, log_err, ...))
    end
  end
end


do
  local redirect = require("lib.fullmoon").serveRedirect
  local check_ok = function (ok, ...)
    if not ok then
      return redirect(500)
    end
    return ...
  end

  catch = function (execute)
    return function (...)
      return check_ok(xpcall(execute, log_err, ...))
    end
  end
end


return {
  catch = need(catch, "function"),
  catch_json = need(catch_json, "function")
}