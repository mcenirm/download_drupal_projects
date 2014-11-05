#!/bin/bash

Usage () {
  cat >&2 <<EOF
Usage: $0 [OPTIONS] <project> ...
Where:
  <project>  project name on drupal.org (eg, drupal or views)
Options:
  --core=N   major version of Drupal core [7]
  --         end of options
EOF
}

# major version of Drupal core
core=7

# construct URL of release history
release_history_url () {
  if [[ $# -ne 1 ]] ; then
    echo >&2 Missing project name to ${FUNCNAME}
    exit 1
  fi
  echo "http://updates.drupal.org/release-history/$1/${core}.x"
}

# location of downloaded files
cache=$( dirname "$0" )/cache

# location of downloaded release histories
cache_rh=${cache}/release-histories

download_project () {
  if [[ $# -ne 1 ]] ; then
    echo >&2 Missing project name to ${FUNCNAME}
    exit 1
  fi

  rhurl=$( release_history_url "$1" )
  rhfile="${cache_rh}/${1}-${core}.xml"
  rhheaders="${rhfile}.hdr"

  mkdir -p "${cache}" "${cache_rh}" || exit 1
  curl -sSRL -D "${rhheaders}" -o "${rhfile}" "${rhurl}" || exit 1

  dlurl=$( grep -o '<download_link>[^<]*</download_link>' -- "${rhfile}" | head -1 | sed -e 's/<[^>]*>//g' )
  dlfile="${cache}/${dlurl##*/}"
  dlheaders="${dlfile}.hdr"

  if ! [[ -f "${dlfile}" ]] ; then
    curl -sSRL -D "${dlheaders}" -o "${dlfile}" "${dlurl}" || exit 1
    echo "${dlfile}"
  fi
}

while [[ $# -gt 0 ]] ; do
  case "$1" in
    --)  # end of options
      shift
      break
      ;;
    --core=*)
      core=${1#--core=}
      shift
      ;;
    --*)
      echo >&2 "Bad option: $1"
      exit 1
      ;;
    *)  # first non-option argument
      break
      ;;
  esac
done

if [[ $# -lt 1 ]] ; then
  Usage
  exit 1
fi

for project in "$@" ; do
  download_project "${project}"
done

