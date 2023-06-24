#!/bin/bash

declare APPNAME='Redbean Forum POC' curl

if command -v curl.com >/dev/null >&1
  then curl=curl.com
  else curl=curl
fi

error () { echo "$1" >&2; exit 1; }

__fetch ()
{
  test -f "$1" && return 0
  echo "  curled:  ${1} ($2)"
  "$curl" "$2" > "$1" 2>/dev/null
}


build ()
{
  local latest filename="$1"
  latest="$(curl https://redbean.dev/latest.txt 2>/dev/null)"

  if ! test -f redbean-"${latest}".com
    then if ! curl -o redbean-"${latest}".com "https://redbean.dev/redbean-${latest}.com"
      then error "Failed to fetch latest redbean.com"
    fi
  fi

  test -f "$filename" && rm "$filename"
  cp redbean-"${latest}".com "$filename"

  local -a files=( "$filename" )

  test -f .init.lua     && files+=( .init.lua )
  test -f .args         && files+=( .args )
  test -f .redbean.png  && files+=( .redbean.png )
  test -f .reload.lua   && files+=( .reload.lua )
  test -f index.lua     && files+=( index.lua )
  test -f index.html    && files+=( index.html )
  test -d .lua          && files+=( .lua )

  if test -f .fetch
    then while read -r file url
      do __fetch "$file" "$url" || exit 1
    done < <(cat .fetch <(echo "\n"))
  fi

  zip.com -r "$filename" "${files[@]}" || error "failed to zip"
  printf "\nGenerated %s\n" "$filename"
  chmod +x "$filename" || exit 1
}

clean ()
{
  rm redbean-*.com
  rm "$1"
  return 0
} >/dev/null 2>&1


setup ()
{
  __fetch definitions.lua "https://raw.githubusercontent.com/jart/cosmopolitan/master/tool/net/definitions.lua"
}

run () {
  unset LUA_PATH
  unset LUA_CPATH
  local file="$1"
  shift
  ./"$file" "$@"
}

help()
{
  cat << HELP
make.sh
  Just a simple build script for redbean applications

Commands
  build (default)   Build a redbean application
  setup             Setup definitions.lua
  clean             Clean build directory
  help              This help text
  run               Run application
HELP
  return 0
}

main ()
{
  local filename command
  filename="$(printf '%s' "${APPNAME}" | tr '[:upper:]' '[:lower:]')"
  filename="${filename// /_}.com"
  command="${1:-build}"
  shift
  case $command in
    (setup) setup ; exit $?
      ;;
    (build) build "$filename" ; exit $?
      ;;
    (clean) clean "$filename" ; exit $?
      ;;
    (run) build "$filename" && run "$filename" "$@"|| exit $?
      ;;
    (*) help && exit $?
      ;;
  esac
}

export -f error

main "$@"

