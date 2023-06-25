local fm = require("lib.external.fullmoon")
local get = require("lib.config").get
local log = require("lib.logging")
local ulib = require("lib.uuid").new
local need = require("lib.need")
local const = require("constants")
local database = require("lib.database")

local cAttachmentsEnabled = "attachments.enabled"
local cAttachmentsUploadPath = "attachments.upload_filepath"
local cAttachmentsMaxUploadSize = "attachments.max_upload_size"
local cAttachmentsCleanupSchedule = "attachments.cleanup_schedule"

do
  local register_cfg = require("lib.config").register
  register_cfg(cAttachmentsEnabled, true)
  register_cfg(cAttachmentsUploadPath, "uploads")
  register_cfg(cAttachmentsMaxUploadSize, 50 * 1024 * 1024) -- 50MB default
  register_cfg(cAttachmentsCleanupSchedule, "*/30 * * * *")
end

do
  local db = database.get(unix.getpid(), const.db_name)
  db:execute([[
    CREATE TABLE IF NOT EXISTS attachments (
      id            INTEGER   PRIMARY KEY   AUTOINCREMENT,
      uuid          TEXT      NOT NULL,
      post_id       INTEGER   NOT NULL,
      filename      TEXT      NOT NULL,
      description   TEXT,

      FOREIGN KEY(post_id) REFERENCES threads(id),
    );
  ]])
end

local insert_attachment <const> = [[
  INSERT INTO attachments (
    uuid, post_id, location, description, filename
  ) VALUES (?, ?, ?, ?);
]]

local delete_attachment <const> = [[
  DELETE FROM
    attachments
  WHERE
    uuid = ?;
]]

local fetch_orphaned_attachments <const> = [[
  SELECT
    l.id   AS id,
    l.uuid AS uuid
  FROM
    attachments AS l
  INNER JOIN posts AS r ON
    1 = 1 // lol
  WHERE EXISTS (
    SELECT * FROM posts r WHERE l.post_id = r.id
  );
]]


-- TODO: replace this with a call to errors.lua
local error_logger
do
  local traceback = debug.traceback
  error_logger = function ()
    log.error(traceback())
  end
end


---@param uuid string
---@param post_id number
---@param data string
local save_attachment = function (uuid, post_id, data)
  local err

  if not get(cAttachmentsEnabled) then
    error("attachments disabled")
  end

  if #data > get(cAttachmentsMaxUploadSize) then
    error("attachment exceeds maximum allowed size")
  end

  local upload_path = get(cAttachmentsUploadPath) .. "/" .. tostring(post_id) .. "/" .. uuid

  local ok, fd = xpcall(assert, error_logger, unix.open, upload_path, unix.O_WRONLY | unix.O_CREAT)
  if not ok then
    error("internal server error")
  end

  ok, err = unix.write(fd, data)
  if not ok then
    log.error(err)
    error("internal server error")
  end
end


---@param post_id number
---@param uuid string
---@return boolean
---@return string
local remove_attachment = function (post_id, uuid)
  local upload_path = get(cAttachmentsUploadPath .. "/" .. tostring(post_id) .. "/" .. uuid)
  local ok, err = unix.rmrf(upload_path)
  if not ok then
    return false, err
  end

  return true
end


-- TODO: since adding attachments to the zip itself could be problematic
-- (if convenient) it would be a better idea to just store files in a
-- configurable location and serve them directly.
--
-- additionally, it may be a good idea to provide a configuration to run
-- an application against a file on every upload. that would allow for a
-- bit of flexibility in case someone wishes to (for example) run an anti
-- viral detection script, or perhaps perform some other nuanced operation
-- upon file attachment. if that is implemented, however, care should be
-- taken to ensure that in no way can this result in RCE.
---@param post_id integer
---@param filename string
---@param data string
---@param description string?
---@return boolean
---@return string?
local add = function (post_id, filename, data, description)
  local uuid = ulib.new()

  do
    local ok, err = pcall(save_attachment, uuid, post_id, data)
    if not ok then
      return false, err
    end
  end

  local db = database.get(unix.getpid(), const.db_name)
  local changes, err = db:execute(insert_attachment, uuid, post_id, filename, description)
  if not changes or changes < 1 then
    return false, err
  end

  return true
end

---@param uuid string
---@return boolean
---@return string?
local delete = function (uuid)
  local db = database.get(unix.getpid(), const.db_name)
  local changes, err = db:execute(delete_attachment)
  if not changes or changes < 1 then
    return nil, err
  end

  return true
end


do
  local pid = unix.getpid()
  local ppid = unix.getppid()

  if pid == ppid then
    local fmt = string.format
    local w_attachments = require("lib.plurals")("attachment", "attachments")
    fm.setSchedule(get(cAttachmentsCleanupSchedule), function ()
      log.info("Checking for orphaned attachments ...")

      local db = database.get(unix.getpid(), const.db_name)
      local results = db:fetchAll(fetch_orphaned_attachments)

      local count = 0
      for _, row in ipairs(results) do
        delete(row.uuid)
        local changes = db:execute([[ DELETE FROM attachments WHERE id = ?; ]], row.id)
        count = count + changes
      end

      log.info(fmt("attachment cleanup : removed %d %s", count, w_attachments(count)))
    end)
  end
end

return {
  add    = need(add, "number", "string", "string", "string?"),
  delete = need(delete, "number", "string"),

  cAttachmentsEnabled = cAttachmentsEnabled,
  cAttachmentsUploadPath = cAttachmentsUploadPath,
  cAttachmentsMaxUploadSize = cAttachmentsMaxUploadSize,
  cAttachmentsCleanupSchedule = cAttachmentsCleanupSchedule,
}
