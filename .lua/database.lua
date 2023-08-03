local fm = require("lib.fullmoon")

local handles = {}

local connect = function (pid, db_name)
  local db = fm.makeStorage(db_name)
  if not handles[pid] then
    handles[pid] = {}
  end

  handles[pid][db_name] = db
  return db
end

local close_all = function (pid)
  if not handles[pid] then
    return
  end

  for _, handle in pairs(handles[pid]) do
    handle:close()
  end
end

local get = function (pid, db_name)
  return assert(handles[pid], "no db handler for pid!")
end

return {
  connect = connect,
  get = connect,
}