#!/bin/sh

want="$1" ; name="$2" ; shift 2
donor="$( which "$want" )"

error ()
{
  printf '%s\n' "$1"
  exit 1
}

fetch ()
{
  test -f "$1" && return 0
  mkdir -p "$(dirname "$1")" || return 1
  echo "  curled: '${2}' -> '${1}'"
  curl.com "$2" > "$1" 2>/dev/null
}

get_lines ()
{ # this is done via a grep, so as using while < $file will skip the last line if there is no trailing line
  grep '[\r\n]*$' "$1" | grep -v '^[:space]*$'
}

prepare ()
{
  test -n "$want"                     || error "error: please provide a target pkzip binary"
  command -v "$want" >/dev/null 2>&1  || error "error: ${want} is not in path"
  test -f "$want"                     && rm "$want"
  test -f "$name"                     && rm "$name"

  if test -f .fetch
  then get_lines .fetch | while read -r file url
      do fetch "$file" "$url" || exit 1
    done
  fi
}

for need in "$want" curl.com zip.com cp mv echo test
  do command -v "$need" >/dev/null 2>&1 || error "missing requirement: ${need}"
done

echo "Making $name from ${want}"    \
  && prepare                        \
  && cp "$donor" "${want}.zip"      \
  && zip.com -r "${want}.zip" "$@"  \
  && mv "${want}.zip" "${name}"     \
  && echo Done                      \
  && exit 0
error "Failed to package ${name}"