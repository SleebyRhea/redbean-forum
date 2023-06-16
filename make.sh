#!/bin/bash

declare APPNAME='Redbean Test'

error () { echo "$1" >&2; exit 1; }
append_dir ()
{
  local file="../${1}"
  cd "$2" || exit 1
  zip -u "$file" .
}

export -f error
export -f append_dir

build ()
{
  local filename="$1"
  local latest="$2"
  if ! test -f redbean-"${latest}".com
    then if ! curl -o redbean-"${latest}".com "https://redbean.dev/redbean-${latest}.com"
      then error "Failed to fetch latest redbean.com"
    fi
  fi

  test -f "$filename" && rm "$filename"
  cp redbean-"${latest}".com "$filename"
  chmod +x "$filename" || exit 1

  local -a files=( "$filename" )
  test -f .init.lua     && files+=( .init.lua )
  test -f .args         && files+=( .args )
  test -f .redbean.png  && files+=( .redbean.png )
  test -f .reload.lua   && files+=( .reload.lua )

  zip "$filename" "${files[@]}" || error "failed to zip"
  if test -d src
    then append_dir "$filename" src || error "failed to append contents of src to ${filename}"
  fi

  exit 0
}

clean ()
{
  rm redbean-*.com
  rm "$1"
  exit 0
} >/dev/null 2>&1

help()
{
  cat << HELP
make.sh
  Just a simple build script for redbean applications

Commands
  build (default)   Build a redbean application
  clean             Clean build directory
  help              This help text
HELP
}

main ()
{
  local filename
  filename="$(printf '%s' "${APPNAME}" | tr '[:upper:]' '[:lower:]')"
  filename="${filename// /_}.com"
  case "${1:-build}" in
    (build) build "$filename" "$(curl https://redbean.dev/latest.txt 2>/dev/null)" ;;
    (clean) clean "$filename"                                                      ;;
    (*)     help                                                                   ;;
  esac
}

main "$@"

