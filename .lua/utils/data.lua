local json_response = function (code, data)
  local meta = { code = code }

  if code >= 200 and code <= 299 then
    return EncodeJson({
      meta = meta,
      response = data
    })
  end

  meta.message = tostring(data)
  return EncodeJson({
    meta = meta
  })
end

return {
  json_response = json_response
}