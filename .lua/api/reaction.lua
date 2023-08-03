local insert_reaction_query <const> = [[
  INSERT INTO reactions (
    author_id, emoji
  ) VALUES (?, ?);
]]
