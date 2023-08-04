local email_regex <const> = [[^[^][<>(){}\\.,;:@"[:space:]\]+(\.[^][<>(){}\\.,;:@"[:space:]\]+)*@([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$]]
local uuid_regex <const> = [[^[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}$]]
local id_regex <const> = [[^[0-9]+$]]
local db_name <const> = "forum.db"

return {
  re = {
    email = assert(re.compile(email_regex), "could not compile " .. email_regex),
    uuid = assert(re.compile(uuid_regex), "could not compile " .. uuid_regex),
    id = assert(re.compile(id_regex), "could not compile " .. id_regex)
  },
  id_regex_str = id_regex,
  email_regex_str = email_regex,
  uuid_regex_str = uuid_regex,
  db_name = db_name,
}