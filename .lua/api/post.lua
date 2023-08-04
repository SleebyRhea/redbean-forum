local api = require("api.api_class")("post")
local uapi = require("api.user")
local need = require("utils.need")
local new_uuid = require("utils.uuid").new
local queries = require("constants.queries")
local endpoint = require("utils.endpoint").new
local json_response = require("utils.data").json_response
local database = require("utils.database")
local const = require("constants")

local qc_post <const> = queries.insert.post
local qs_by_uuid <const> = queries.select.post_by_uuid
local qs_by_thread_uuid <const> = queries.select.posts_by_thread_uuid

local create_post = function (body, thread_id, author_id)
  local uuid = new_uuid()
  local id, post
  local now = GetTime()

  do
    local db = database.get(unix.getpid(), const.db_name)
    local c, err = db:execute(qc_post, uuid, body, author_id, now, now)
    if c < 1 then
      return false, "failed to create post: " .. tostring(err)
    end
  end

  return true
end

local search_posts_by_regex = function (query, offset, limit)
  local regex, err = re.compile(query)
  if not regex then
    return nil, "invalid regex: " .. tostring(err)
  end
end

local search_posts_by_description = function (query)
end


do --[[ GET methods ]]--
  local public_by_uuid = function (req)
  end

  local public_by_thread = function (req)
  end

  local public_list_by_author = function (req)
  end

  local public_search = function (req)
  end
end


do --[[ POST methods ]]--
  local public_create_post = function (req)
    local ok, err = create_post(req.params.body, req.params.thread_id, req.params.author_id)
    if not ok
      then return json_response(500, err)
      else return json_response(200, "success")
    end
  end

  api.post.create_post = endpoint(public_create_post)
    .must_pass(uapi.require_auth)
    .has_param("body", "string")
    .has_param("thread_id", "number")
    .has_param("author_id", "number")()
end

return {
  api = api,
  create_post = need(create_post, "string", "number", "number")
}