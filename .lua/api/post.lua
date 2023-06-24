local database = require("lib.database")
local context = require("context").new
local const = require("constants")
local user = require("api.user")
local need = require("lib.need")
local fm = require("fullmoon")

local api = {
  get  = { directory = {}, thread = {}, post = {} },
  post = { directory = {}, thread = {}, post = {} },
  push = { directory = {}, thread = {}, post = {} },
}

do
  local db = database.get(unix.getpid(), const.db_name)
  db:execute([[
    CREATE TABLE IF NOT EXISTS directory (
      id          INTEGER   PRIMARY KEY   AUTOINCREMENT,
      name        TEXT      NOT NULL,
      parent_id   INTEGER
    );

    CREATE TABLE IF NOT EXISTS threads (
      id            INTEGER   PRIMARY KEY   AUTOINCREMENT,
      uuid          TEXT      NOT NULL      UNIQUE,
      name          TEXT      NOT NULL,
      author_id     TEXT      NOT NULL,
      created_on    INTEGER   NOT NULL,
      updated_on    INTEGER   NOT NULL,
      directory_id  INTEGER   NOT NULL
    );

    CREATE TABLE IF NOT EXISTS posts (
      id          INTEGER   PRIMARY KEY   AUTOINCREMENT,
      uuid        TEXT      NOT NULL      UNIQUE,
      body        TEXT      NOT NULL,
      thread_id   INTEGER   NOT NULL,
      author_id   INTEGER   NOT NULL,
      extra_data  TEXT
    );

    CREATE TABLE IF NOT EXISTS reactions (
      id          INTEGER   PRIMARY KEY  AUTOINCREMENT,
      author_id   INTEGER   NOT NULL,
      emoji       TEXT
    );
  ]])
end

local insert_thread <const> = [[
  INSERT INTO threads (
    name, parent_id
  ) VALUES (?, ?);
]]

local insert_post <const> = [[
  INSERT INTO posts (
    uuid,       name,       author_id,
    created_on, updated_on, directory_id
  ) VALUES ( ?, ?, ?, ?, ?, ? );
]]

local insert_reaction <const> = [[
  INSERT INTO reactions (
    author_id, emoji
  ) VALUES (?, ?);
]]

local select_threads_by_author_id <const> = [[
  SELECT
    r.id        AS id,
    r.uuid      AS uuid
  FROM
    threads l
  INNER JOIN posts r ON
    l.id = r.thread_id
  WHERE
    l.author_id = ?
  LIMIT ? OFFSET ?;
]]

local select_posts_by_thread_uuid <const> = [[
  SELECT
    r.id          AS id,
    r.body        AS body,
    l.author_id   AS author
  FROM
    threads l
  INNER JOIN posts r ON
    l.id == r.thread_id
  WHERE
    l.uuid = ?
  LIMIT ? OFFSET ?;
]]


--
-- DIRECTORIES
--

do --[[ GET methods ]]--
  local directory_by_uuid = function (req)
  end

  local directory_by_name = function (req)
  end

  local directory_list_all = function (req)
  end

  api.get.directory.by_uuid = ''
  api.get.directory.by_name = ''
  api.get.directory.list_all = ''

end


--
-- THREADS
--

do --[[ GET methods ]]--
  local thread_by_name = function (req)
  end

  local thread_search_by_name = function (req)
  end

  local thread_by_author_uuid = function (req)
  end

  local thread_list_by_author = function (req)
  end

  local thread_list_all_threads = function (req)
  end

  api.get.thread.search = context(thread_search_by_name).must_pass(user.require_auth).init()
  api.get.thread.by_uuid = context(thread_by_author_uuid).must_pass(user.require_auth).init()
  api.get.thread.by_name = context(thread_by_name).must_pass(user.require_auth).init()
  api.get.thread.list_all = context(thread_list_all_threads).must_pass(user.require_auth).init()
  api.get.thread.list_by_author = context(thread_list_by_author).must_pass(user.require_auth).init()
end


do --[[ POST methods ]]--

end


--
-- POSTS
--

do --[[ GET methods ]]--

end

return {
  api = api,
}