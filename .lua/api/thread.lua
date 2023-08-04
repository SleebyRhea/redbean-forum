
local insert_thread_query <const> = [[
  INSERT INTO threads (
    name, parent_id
  ) VALUES (?, ?);
]]

local select_threads_by_author_id_query <const> = [[
  SELECT
    r.id        AS id,
    r.uuid      AS uuid
  FROM
    threads l
  INNER JOIN posts r ON
    l.id = r.thread_id
  WHERE
    l.author_id = ?
  OFFSET ? LIMIT ?;
]]

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

  api.get.thread.search = endpoint(thread_search)()
  api.get.thread.by_uuid = endpoint(thread_by_author_uuid).must_pass(uapi.require_auth)()
  api.get.thread.list_all = endpoint(thread_list_all_threads).must_pass(uapi.require_auth)()
  api.get.thread.list_by_author = endpoint(thread_list_by_author).must_pass(uapi.require_auth)()
end