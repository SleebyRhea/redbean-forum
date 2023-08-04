---@class User
---@field created_on integer
---@field email      string
---@field uuid       string
---@field name       string

local fm = require("lib.fullmoon")
local need = require("utils.need")
local const = require("constants")
local queries = require("constants.queries")
local new_uuid = require("utils.uuid").new
local endpoint = require("utils.endpoint").new
local database = require("utils.database")
local json_response = require("utils.data").json_response
local validate = require("utils.validation").validate
local api = require("api.api_class")("user")

local cUserPasswordRegex = "user.password_regex"

do
  local register_cfg = require("utils.config").register
  register_cfg(cUserPasswordRegex, "")
end

local qc_user <const> = queries.insert.user
local qc_usersettings <const> = queries.insert.user_settings
local qs_user_by_uuid <const> = queries.select.user_by_uuid
local qs_userauth_by_id <const> = queries.select.userauth_by_id
local qs_userdata_by_uuid <const> = queries.select.userdata_by_uuid
local qs_userdata_by_name <const> = queries.select.userdata_by_name
local qu_usersettings_by_uuid <const> = queries.update.usersettings_by_uuid

local require_auth = function (req)
  if (not req.session.authenticated)
  or (not type(req.session.context) == "table")
  or (not type(req.session.context.user) == "table")
  then
    error(fm.serveError(403, "unauthorized"))
  end
end

local require_admin = function (level)
  return function (req)
  end
end


---@param uuid string
---@return User?
---@return integer|string?
local user_by_uuid = function (uuid)
  assert(validate("uuid", uuid))

  local id, created_on, name, email, email_visible
  do
    local db = database.get(unix.getpid(), const.db_name)
    local result = db:fetchOne(qs_userdata_by_uuid, uuid)
    if not result or not result.id then
      return nil
    end

    id = tonumber(result.id)
    name = tostring(result.name)
    email = tostring(result.email)
    created_on = tonumber(result.created_on)
  end

  return {
    email_visible = email_visible,
    created_on = created_on,
    email = email,
    uuid = uuid,
    name = name,
  }, id
end


---@param name string
---@return User?
---@return integer?
local user_by_name = function (name)
  assert(type(name) == "string", "user_by_name requires a string")

  local id, created_on, uuid, email
  do
    local db = database.get(unix.getpid(), const.db_name)

    local result = db:fetchOne(qs_userdata_by_name, name)
    if not result or not result.id then
      return nil
    end

    created_on = tonumber(result.created_on)
    uuid = tostring(result.uuid)
    email = tostring(result.email)
    id = tonumber(result.id)
  end

  return {
    created_on = created_on,
    email = email,
    uuid = uuid,
    name = name,
  }, id
end


---@param email string
---@return User?
---@return integer?
local user_by_email = function (email)
end


---create a new user and add them to the database
---@param username string
---@param email string
---@param password string
---@return boolean
---@return string?
local create_user = function (username, email, password)
  do
    local ok, err = validate("email", email)
    if not ok then
      return false, err
    end
  end

  do
    local ok, err = validate("password", password)
    if not ok then
      return false, err
    end
  end

  if user_by_name(username) or user_by_email(email) then
    return false, "user exists"
  end

  do
    local db = database.get(unix.getpid(), const.db_name)
    local uuid = new_uuid()
    local hash = argon2.hash_encoded(password, EncodeBase64(GetRandomBytes(32)))
    local user_id = -1

    do
      local _, err = db:execute(qc_user, uuid, GetTime())
      if err then
        return false, err
      end
    end

    do
      local result, err = db:fetchOne(qs_user_by_uuid, uuid)
      if not result then
        return false, err
      end
      user_id = result.id
    end

    do
      local _, err = db:execute(qc_usersettings, user_id, username, hash, email, false)
      if err then
        return false, err
      end
    end
  end

  return true
end

local update_user

do
  local handlers = {}

  handlers.username = function (db, uuid, value)
    do
      local ok, err = validate("username", value)
      if not ok then
        return false, err
      end
    end

    local _, err = db:execute(qu_usersettings_by_uuid, "name", value, uuid)

    if err then
      return false, err
    end

    return true
  end


  handlers.password = function (db, uuid, value)
    do
      local ok, err = validate("password", value)
      if not ok then
        return false, err
      end
    end

    local hash = argon2.hash_encoded(value, EncodeBase64(GetRandomBytes(32)))
    local _, err = db:execute(qu_usersettings_by_uuid, "auth", hash, uuid)

    if err then
      return false, err
    end

    return true
  end


  handlers.email = function (db, uuid, value)
    local _, err = db:execute(qu_usersettings_by_uuid, "email", value, uuid)

    if err then
      return false, err
    end

    return true
  end

  ---Update a user value
  ---@param uuid string
  ---@param field string
  ---@param value any
  ---@return boolean
  ---@return string?
  update_user = function (uuid, field, value)
    local handler = handlers[field]
    if not handler then
      return false, "invalid field"
    end

    local db = database.get(unix.getpid(), const.db_name)
    local ok, err = handler(db, uuid, value)
    if not ok then
      return false, err
    end

    return true
  end
end


do -- [[ GET methods ]]
  ---get a user by their UUID
  ---@param req table
  ---@return any
  local public_by_uuid = function (req)
    local uuid = req.params.uuid
    if not uuid then
      return json_response(400, "bad request")
    end

    local user = user_by_uuid(uuid)
    if not user then
      return json_response(404, "no such user")
    end

    return json_response(200, user)
  end


  ---get a user by their email
  ---@param req table
  ---@return any
  local public_by_email = function (req)
    local uuid = req.params.uuid
    if not uuid then
      return json_response(400, "bad request")
    end

    local user = user_by_uuid(uuid)
    if not user then
      return json_response(404, "no such user")
    end

    return json_response(200, user)
  end


  ---get a user by their name
  ---@param req table
  ---@return any
  local public_by_name = function (req)
    local name = req.params.name
    if not name then
      return json_response(400, "bad request")
    end

    local user = user_by_name(name)
    if not user then
      return json_response(404, "no such user")
    end

    return json_response(200, user)
  end


  ---@param req any
  ---@return string|nil
  local public_want_self = function (req)
    return json_response(200, req.session.user)
  end


  ---@return unknown
  local public_authenticate = function (req)
    local user --[[@as User]]
    local id --[[@as integer]]
    local login = req.params.login
    local passw = req.params.password

    if not user then
      local attempt, attempt_id = user_by_name(login)
      if attempt then
        user = attempt
        id = attempt_id
      end
    end

    do
      local attempt, attempt_id = user_by_email(login)
      if attempt then
        user = attempt
        id = attempt_id
      end
    end

    if not user then
      return json_response(403, "unauthorized")
    end

    local db = database.get(unix.getpid(), const.db_name)
    local result = db:fetchOne(qs_userauth_by_id, id)
    if not result then
      return json_response(403, "unauthorized")
    end

    if not argon2.verify(tostring(result.auth), passw) then
      return json_response(403, "unauthorized")
    end

    req.session.authenticated = true
    req.session.endpoint = {
      user = user,
    }

    return json_response(200, "success")
  end

  api.get.self = endpoint(public_want_self)
    .must_pass(require_auth)()

  api.get.by_uuid = endpoint(public_by_uuid)
    .has_param("uuid", "string")()

  api.get.by_name = endpoint(public_by_name)
    .has_param("name", "string")()

  api.get.by_email = endpoint(public_by_email)
    .has_param("email", "string")()

  api.get.authenticate = endpoint(public_authenticate)
    .has_param("login", "string")
    .has_param("password", "string")()
end


do --[[ POST methods ]]
  local register_user = function (req)
    local email = req.params.email
    local username = req.params.username
    local password = req.params.password

    local ok, err = create_user(username, email, password)
    if not ok then
      return json_response(401, err)
    end
  end

  api.post.register = endpoint(register_user)
    .has_param("username", "string")
    .has_param("password", "string")
    .has_param("email", "string")()
end


do --[[ PATCH methods ]]
  local update = function (req)
    local uuid = req.session.context.user.uuid
    local field = req.params.field
    local value = req.params.value

    if not (field and value and uuid) then
      return json_response(400, "bad request")
    end

    local ok, err = update_user(uuid, field, value)
    if not ok then
      return json_response(500, err)
    end

    return json_response(200, "success")
  end

  api.patch.update = endpoint(update).must_pass(require_auth)()
end

return {
  api = api,
  require_auth = require_auth,
  require_admin = require_admin,
  user_by_uuid = need(user_by_uuid, "string"),
  user_by_name = need(user_by_name, "string"),
  create_user = need(create_user, "string", "string", "string"),
  update_user = need(update_user, "string", "string")
}