local fm = require("lib.external.fullmoon")
local const = require("constants")
local get = require("lib.config").get
local database = require("lib.database")
local handlers = require("lib.handlers")
local GET, POST, PUSH = fm.GET, fm.POST, fm.PUSH

fm.setTemplate({ "/tmpl/", fmt = "fmt" })
fm.setRoute("*", "/assets/*")

do --[[ /v1/user ]]--
  local uapi = require("api.user").api
  fm.setRoute(GET("/v1/user/authenticate"), uapi.get.authenticate)
  fm.setRoute(GET("/v1/user"), uapi.get.self)
  fm.setRoute(GET({"/v1/user/:uuid", uuid = {regex = const.uuid_regex}}), uapi.get.by_uuid)
  fm.setRoute(GET({"/v1/user/:email", email = {regex = const.email_regex}}), uapi.get.by_email)
  fm.setRoute(GET("/v1/user/:name"), uapi.get.by_name)

  fm.setRoute(POST("/v1/user/register"), uapi.post.register)
  -- fm.setRoute(PUSH("/v1/user/:field"), uapi.push)
end


do --[[ /v1/post ]]--
  local papi = require("api.post")
  -- fm.setRoute(GET("/v1/thread/list", papi.get.list))
  -- fm.setRoute(GET("/v1/thread/:uuid"), papi.get.uuid)
  -- fm.setRoute(GET("/v1/thread/search"), papi.get.list)

  -- fm.setRoute(POST("/v1/thread/:uuid/comment"), papi.post)
  -- fm.setRoute(POST)

end

do
  if OnWorkerStart then
    handlers.register_handler("OnWorkerStart", OnWorkerStart)
  end

  OnWorkerStart = function ()
    database.create(unix.getpid(), const.db_name)
    handlers.call_handlers("OnWorkerStart")
  end
end

do
  if OnWorkerStop then
    handlers.register_handler("OnWorkerStop", OnWorkerStop)
  end

  OnWorkerStop = function ()
    handlers.call_handlers("OnWorkerStop")
    database.close_all(unix.getpid())
  end
end

do
  if OnHttpRequest then
    handlers.register_handler(OnHttpRequest, OnHttpRequest)
  end

  OnHttpRequest = function ()
    handlers.call_handlers("OnHttpRequest")
  end
end

fm.run()