local context = require("context").new
local const = require("constants")
local user = require("api.user")
local fm = require("fullmoon")

local api = {
  get  = { thread = {}, comment = {} },
  post = { thread = {}, comment = {} },
  push = { thread = {}, comment = {} }
}

do
  local db <close> = fm.makeStorage(const.db_name, [[
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

    CREATE TABLE IF NOT EXISTS attachments (
      id            INTEGER   PRIMARY KEY   AUTOINCREMENT,
      post_id       INTEGER   NOT NULL,
      location      TEXT,
      description   TEXT
    );
  ]])
end

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

do --[[ GET methods ]]--
  local thread_search_by_name = function (req)
  end

  local thread_by_author_uuid = function (req)
  end


  api.get.list = context(list).must_pass(user.require_auth).init()
  api.get.thread.search = context(thread_search_by_name).must_pass(user.require_auth).init()
  api.get.thread.by_uuid = context(thread_by_author_uuid).must_pass(user.require_auth).init()
  api.get.thread.by_uuid = context(by_uuid).must_pass(user.require_auth).init()
end


do --[[ POST methods ]]--

end


return {
  api = api,
}