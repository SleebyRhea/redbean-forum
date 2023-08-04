local queries <const> = {
  insert = {},
  select = {},
  update = {},
  delete = {},
}

---
--- INSERT
---

queries.insert.user = [[
  INSERT INTO users (
    uuid,
    created_on
  ) VALUES (?, ?);
]]

queries.insert.user_settings = [[
  INSERT INTO user_settings (
    user_id,
    name,
    auth,
    email,
    email_visible
  ) VALUES (?, ?, ?, ?, ?);
]]

queries.insert.directory = [[
  INSERT INTO directory (
    name, parent_id
  ) VALUES (?, ?);
]]

queries.insert.thread = [[
  INSERT INTO threads (
    name, parent_id
  ) VALUES (?, ?);
]]

queries.insert.post = [[
  INSERT INTO posts (
    uuid,       body,       author_id,
    created_on, updated_on
  ) VALUES ( ?, ?, ?, ?, ? );
]]

queries.insert.reaction = [[
  INSERT INTO reactions (
    author_id, emoji
  ) VALUES (?, ?);
]]

queries.insert.attachment = [[
  INSERT INTO attachments (
    uuid, post_id, location, description, filename
  ) VALUES (?, ?, ?, ?);
]]

----
---- SELECT
----

queries.select.user_by_uuid = [[
  SELECT
    id
  FROM
    users
  WHERE
    uuid = ?
  LIMIT 1;
]]

queries.select.userdata_by_name = [[
  SELECT
    l.id              AS id,
    l.uuid            AS uuid,
    r.name            AS name,
    r.email           AS email,
    r.email_visible   AS email_visible,
    l.created_on      AS created_on
  FROM
    users l
  INNER JOIN user_settings r ON
    l.id = r.user_id
  WHERE
    r.name = ?
  LIMIT 1;
]]

queries.select.userdata_by_uuid = [[
  SELECT
    l.id              AS id,
    l.uuid            AS uuid,
    r.name            AS name,
    r.email           AS email,
    r.email_visible   AS email_visible,
    l.created_on      AS created_on
  FROM
    users l
  INNER JOIN user_settings r ON
    l.id = r.user_id
  WHERE
    l.uuid = ?
  LIMIT 1;
]]

queries.select.userauth_by_id = [[
  SELECT
    auth
  FROM
    user_settings
  WHERE
    user_id = ?
  LIMIT 1;
]]

queries.select.directories_all = [[
  SELECT
    id, name, parent_id
  FROM directory
  OFFSET ? LIMIT ?;
]]

queries.select.directories_by_id = [[
  SELECT
    id, name, parent_id
  FROM directory
  WHERE
    id = ?;
]]

queries.select.directories_by_parent = [[
  SELECT
    id, name, parent_id
  FROM directory
  WHERE
    parent_id = ?
  OFFSET ? LIMIT ?;
]]

queries.select.directories_by_name = [[
  SELECT
    id, name, parent_id
  FROM directory
  WHERE
    name = ?
  OFFSET ? LIMIT ?;
]]

queries.select.post_by_uuid = [[
  SELECT
    id, uuid, body, thread_id,
    author_id,  created_on,
    updated_on, extra_data
  FROM posts
  WHERE
    uuid = ?
  LIMIT 1;
]]

queries.select.posts_by_thread_uuid = [[
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

---
--- UPDATE
---

queries.update.directory = [[
  UPDATE directory SET
    ? = ?
  WHERE
    id = ?
  LIMIT 1;
]]

queries.update.usersettings_by_uuid = [[
  UPDATE user_settings SET
    ? = ?
  WHERE
    uuid = ?
  LIMIT 1;
]]


return queries