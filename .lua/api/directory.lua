local api = require("api.api_class")("directory")
local need = require("utils.need")
local uapi = require("api.user")
local context = require("context")
local const = require("constants")
local queries = require("constants.queries")
local database <const> = require("utils.database")
local json_response = require("utils.data").json_response
local push, pop = table.insert, table.remove

local insert_directory_query <const> = queries.insert.directory
local select_directories_query <const> = queries.select.directories_all
local select_directory_by_id_query <const> = queries.select.directories_by_id
local select_directories_by_parent_query <const> = queries.select.directories_by_parent
local select_directories_by_name_query <const> = queries.select.directories_by_name
local update_directory_query <const> = queries.update.directory


---@param id integer
---@return Directory?
---@return integer?
local get_directory_by_id = function (id)
  local name, parent_id

  do
    local db = database.get(unix.getpid(), const.db_name)
    local result = db:fetchOne(select_directory_by_id_query, id)
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


---@param offset integer
---@param limit integer
---@return Directory[]
local get_directory_listing = function (offset, limit)
  local directories = {}

  local db = database.get(unix.getpid(), const.db_name)
  local results = db:fetch(select_directories_query, offset, limit)

  for _, row in ipairs(results) do
    push(directories, {
      id = tonumber(row.id),
      parent_id = tostring(row.parent_id),
      name = tostring(row.name),
    })
  end

  return directories
end

---@param name string
---@param offset integer
---@param limit integer
---@return Directory[]
local get_directory_listing_by_name = function (name, offset, limit)
  ---@type Directory[]
  local directories = {}
  local db = database.get(unix.getpid(), const.db_name)
  local results = db:fetchAll(select_directories_by_name_query, name, offset, limit)

  if not results or #results < 1 then
    return directories
  end

  for _, row in ipairs(results) do
    push(directories, {
      id = tonumber(row.id),
      parent_id = tostring(row.parent_id),
      name = tostring(row.name),
    })
  end

  return directories
end

---@param parent_id integer
---@param offset integer
---@param limit integer
---@return Directory[]
local get_directory_listing_by_parent = function (parent_id, offset, limit)
  ---@type Directory[]
  local directories = {}
  local db = database.get(unix.getpid(), const.db_name)
  local results = db:fetchAll(select_directories_by_parent_query, parent_id, offset, limit)

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

---@param name string
---@param parent_id integer?
---@return boolean
local create_directory = function (name, parent_id)
  local db = database.get(unix.getpid(), const.db_name)
  if db:execute(insert_directory_query, name, parent_id) < 1 then
    return false, "failed to create directory"
  end
  return true
end

---@param id integer
---@param field string
---@param value any
---@return boolean
---@return string?
local update_directory = function (id, field, value)
  local db = database.get(unix.getpid(), const.db_name)
  if db:execute(update_directory_query, id, field, value) then
    return false, "failed to create directory"
  end
  return true
end

do --[[ GET methods ]]--
  local get_directory_list_all = function (req)
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

  local get_directory_by_name = function (req)
    return json_response(403, "unimplemented")
  end

  local get_directory_list_by_parent = function (req)
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

    return json_response(200, get_directory_listing_by_parent(parent_id, offset, limit))
  end

  api.get.list_all = context(get_directory_list_all)()
  api.get.list_by_parent = context(get_directory_list_by_parent)()
  api.get.list_by_name = context(get_directory_by_name)()
end


do --[[ POST methods ]]--
  ---@param req table
  local post_directory_create = function (req)
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

  api.post.create = context(post_directory_create)
    .must_pass(uapi.require_auth)
    .must_pass(uapi.require_admin(1))
    ()
end


do --[[ PATCH methods ]]--
  local patch_update_directory_field = function (req)
    local id = tonumber(req.params.id)
    local field = req.params.field
    local value = req.params.value

    if not id or type(id) ~= "number" then
      return json_response(400, "bad request (invalid parameter)")
    end

    if type(field) ~= "string" or field == "" then
      return json_response(400, "bad request (invalid parameter)")
    end

    return json_response(200, update_directory(id, field, value))
  end

  api.patch.update = context(patch_update_directory_field)
    .must_pass(uapi.require_auth)
    .must_pass(uapi.require_admin(1))
    ()
end

return {
  api = api,
  create_directory = need(create_directory, "number"),
  update_directory = need(update_directory, "number", "string"),
  get_directory_by_id = need(get_directory_by_id),
  get_directory_listing = need(get_directory_listing, "number", "number"),
  get_directory_listing_by_name = need(get_directory_listing_by_name, "string", "number", "number"),
  get_directory_listing_by_parent = need(get_directory_listing_by_parent, "number", "number", "number"),
}