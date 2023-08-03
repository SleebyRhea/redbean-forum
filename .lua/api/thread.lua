
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