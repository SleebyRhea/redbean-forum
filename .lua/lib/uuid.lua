local new_uuid = function ()
  local base
  repeat
    base = EncodeBase64(GetRandomBytes(64)):gsub("[^%w%d]","")
  until #base >= 32
  return "%s-%s-%s-%s-%s" % { base:sub(1, 32):upper():match("^(........)(....)(....)(....)(............)$") }
end

return {
  new = new_uuid,
}