local api = require("api.api_class")("post")
local queries = require("constants.queries")
local context = require("utils.context").new

local uapi = require("api.user")
local json_response = require("utils.data").json_response

local q_insert <const> = queries.insert.post
local q_by_thread_uuid_query <const> = queries.select.posts_by_thread_uuid

local search_posts_by_regex = function (query, offset, limit)
  local regex, err = re.compile(query)
  if not regex then
    return nil, "invalid regex: " .. tostring(err)
  end
end

local search_posts_by_description = function (query)
end


--
-- THREADS
--

do --[[ GET methods ]]--
  local thread_search = function (req)
  end

  local thread_by_author_uuid = function (req)
  end

  local thread_list_by_author = function (req)
  end

  local thread_list_all_threads = function (req)
  end

  api.get.thread.search = context(thread_search)()
  api.get.thread.by_uuid = context(thread_by_author_uuid).must_pass(uapi.require_auth)()
  api.get.thread.list_all = context(thread_list_all_threads).must_pass(uapi.require_auth)()
  api.get.thread.list_by_author = context(thread_list_by_author).must_pass(uapi.require_auth)()
end


do --[[ POST methods ]]--

end


--
-- POSTS
--

do --[[ GET methods ]]--
  local post_by_uuid = function (req)
  end

  local post_by_thread = function (req)
  end

  local post_list_by_author = function (req)
  end

  local post_search = function (req)
  end
end

do --[[ POST methods ]]--
end

return {
  api
}