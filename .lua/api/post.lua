local database = require("lib.database")
local validate = require("lib.validation").validate
local context = require("context").new
local const = require("constants")
local user = require("api.user")
local need = require("lib.need")
local fm = require("lib.external.fullmoon")
local push, pop = table.insert, table.remove
local json_response = require("api.data").json_response

local api = {
  get    = { directory = {}, thread = {}, post = {} },
  post   = { directory = {}, thread = {}, post = {} },
  push   = { directory = {}, thread = {}, post = {} },
  patch  = { directory = {}, thread = {}, post = {} },
  delete = { directory = {}, thread = {}, post = {} },
}

do
  local db = database.get(unix.getpid(), const.db_name)
  db:execute([[
    CREATE TABLE IF NOT EXISTS directory (
      id          INTEGER   PRIMARY KEY   AUTOINCREMENT,
      name        TEXT      NOT NULL,
      parent_id   INTEGER,  // the parent directory id is used to allow directories
                            // to be a child of another directory. if there is no
                            // parent_id (parent_id = NULL) then it is in the root
                            // of the directory tree
    );

    CREATE TABLE IF NOT EXISTS threads (
      id            INTEGER   PRIMARY KEY   AUTOINCREMENT,
      uuid          TEXT      NOT NULL      UNIQUE,
      name          TEXT      NOT NULL,
      author_id     TEXT      NOT NULL,
      created_on    INTEGER   NOT NULL,
      updated_on    INTEGER   NOT NULL,
      directory_id  INTEGER   NOT NULL,

      FOREIGN KEY(author_id) REFERENCES users(id),
      FOREIGN KEY(directory_id) REFERENCES directory(id),
    );

    CREATE TABLE IF NOT EXISTS posts (
      id          INTEGER   PRIMARY KEY   AUTOINCREMENT,
      uuid        TEXT      NOT NULL      UNIQUE,
      body        TEXT      NOT NULL,
      thread_id   INTEGER   NOT NULL,
      author_id   INTEGER   NOT NULL,
      extra_data  TEXT,

      FOREIGN KEY(author_id) REFERENCES users(id),
      FOREIGN KEY(thread_id) REFERENCES threads(id),
    );

    CREATE TABLE IF NOT EXISTS reactions (
      id          INTEGER   PRIMARY KEY  AUTOINCREMENT,
      post_id     INTEGER   NOT NULL,
      author_id   INTEGER   NOT NULL,
      emoji       TEXT,

      FOREIGN KEY(author_id) REFERENCES users(id),
      FOREIGN KEY(post_id) REFERENCES threads(id),
    );
  ]])
end

local insert_directory <const> = [[
  INSERT INTO directory (
    name, parent_id
  ) VALUES (?, ?);
]]

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

local select_directories <const> = [[
  SELECT
    id, name, parent_id
  FROM directory
  OFFSET ? LIMIT ?;
]]

local select_directory_by_id <const> = [[
  SELECT
    id, name, parent_id
  FROM directory
  WHERE
    id = ?;
]]

local select_directories_by_parent <const> = [[
  SELECT
    id, name, parent_id
  FROM directory
  WHERE
    parent_id = ?
  OFFSET ? LIMIT ?;
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
  OFFSET ? LIMIT ?;
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
  OFFSET ? LIMIT ?;
]]


---@param id integer
---@return Directory?
---@return integer?
local directory_by_id = function (id)
  local name, parent_id

  do
    local db = database.get(unix.getpid(), const.db_name)
    local result = db:fetchOne(select_directory_by_id, id)
    if not result or not result.id then
      return nil
    end

    name = tostring(result.name)
    parent_id = tonumber(result.parent_id)
  end

  ---@class Directory
  ---@field name string
  ---@field parent_id integer?
  return {
    id = id,
    name = name,
    parent_id = parent_id
  }, id
end


---@param parent_id integer
---@param offset integer
---@param limit integer
---@return Directory[]
local get_directory_by_parent = function (parent_id, offset, limit)
  ---@type Directory[]
  local directories = {}
  local db = database.get(unix.getpid(), const.db_name)
  local results = db:fetchAll(select_directories_by_parent, parent_id, offset, limit)

  if not results or #results < 1 then
    return directories
  end

  for _, row in ipairs(results) do
    push(directories, {
      id = tonumber(row.id),
      parent_id = parent_id,
      name = tostring(row.name),
    })
  end

  return directories
end

---@param offset integer
---@param limit integer
---@return Directory[]
local get_directory_listing = function (offset, limit)
  local directories = {}

  local db = database.get(unix.getpid(), const.db_name)
  local results = db:fetch(select_directories, offset, limit)

  for _, row in ipairs(results) do
    push(directories, {
      id = tonumber(row.id),
      parent_id = tostring(row.parent_id),
      name = tostring(row.name),
    })
  end

  return directories
end

local search_posts_by_regex = function (query, offset, limit)
  local regex, err = re.compile(query)
  if not regex then
    return nil, "invalid regex: " .. tostring(err)
  end
end

local search_posts_by_description = function (query)
end

---@param name string
---@param parent_id integer?
---@return boolean
local create_directory = function (name, parent_id)
  local db = database.get(unix.getpid(), const.db_name)
  if db:execute(insert_directory, name, parent_id) < 1 then
    return false, "failed to create directory"
  end
  return true
end

--
-- DIRECTORIES
--

do --[[ GET methods ]]--
  local directory_list_all = function (req)
    local offset = req.params.offset or 0
    local limit = req.params.limit or 15

    if offset and type(offset) ~= "number" then
      return json_response(400, "bad request (invalid parameter)")
    end

    if limit and type(limit) ~= "number" then
      return json_response(400, "bad request (invalid parameter)")
    end

    return json_response(200, get_directory_listing(offset, limit))
  end

  local directory_list_by_parent = function (req)
    local parent_id = req.params.parent_id
    local offset = tonumber(req.params.offset) or 0
    local limit = tonumber(req.params.limit) or 15

    if not parent_id then
      return json_response(400, "bad request")
    end

    if offset and type(offset) ~= "number" then
      return json_response(400, "bad request (invalid parameter)")
    end

    if limit and type(limit) ~= "number" then
      return json_response(400, "bad request (invalid parameter)")
    end

    return json_response(200, get_directory_by_parent(parent_id, offset, limit))
  end

  api.get.directory.list_all = context(directory_list_all).get_handler()
  api.get.directory.list_by_parent = context(directory_list_by_parent).get_handler()
end

do --[[ POST methods ]]--
  ---@param req table
  local directory_create = function (req)
    local name = req.params.name
    local parent = req.params.parent_id

    if not name or type(name) ~= "string" then
      return json_response(400, "bad request (invalid parameter)")
    end

    if parent and type(parent) ~= "number" then
      return json_response(400, "bad request (invalid parameter)")
    end

    if create_directory(name, parent) then
      return json_response(200, "success")
    end
  end

  api.post.directory.create = context(directory_create)
    .must_pass(user.require_auth)
    .must_pass(user.require_admin(1))
    .get_handler()
end

do --[[ PATCH methods ]]--
  local patch_directory_field = function ()

  end
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

  api.get.thread.search = context(thread_search).get_handler()
  api.get.thread.by_uuid = context(thread_by_author_uuid).must_pass(user.require_auth).get_handler()
  api.get.thread.list_all = context(thread_list_all_threads).must_pass(user.require_auth).get_handler()
  api.get.thread.list_by_author = context(thread_list_by_author).must_pass(user.require_auth).get_handler()
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

return {
  api = api,
  get_directory_by_parent = need(get_directory_by_parent, "number", "number", "number"),
  get_directory_listing = need(get_directory_listing, "number", "number")
}