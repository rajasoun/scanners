#!/usr/bin/env bash

NC=$'\e[0m' # No Color
BOLD=$'\033[1m'
UNDERLINE=$'\033[4m'
RED=$'\e[31m'
GREEN=$'\e[32m'
BLUE=$'\e[34m'
ORANGE=$'\x1B[33m'

# check pre-conditions
function check_pre_conditions(){
    if ! [ -x "$(command -v docker)" ]; then
        echo 'Error: docker is not installed.' >&2
        echo 'Goto https://www.docker.com/products/docker-desktop'
        exit 1
    fi
}

# raise error
function raise_error(){
  echo -e "${BOLD}${RED}${1}${NC}" >&2
  exit 1
}

# workaround for path limitations in windows
function _docker() {
  export MSYS_NO_PATHCONV=1
  export MSYS2_ARG_CONV_EXCL='*'

  case "$OSTYPE" in
      *msys*|*cygwin*) os="$(uname -o)" ;;
      *) os="$(uname)";;
  esac

  if [[ "$os" == "Msys" ]] || [[ "$os" == "Cygwin" ]]; then
      # shellcheck disable=SC2230
      realdocker="$(which -a docker | grep -v "$(readlink -f "$0")" | head -1)"
      printf "%s\0" "$@" > /tmp/args.txt
      # --tty or -t requires winpty
      if grep -ZE '^--tty|^-[^-].*t|^-t.*' /tmp/args.txt; then
          #exec winpty /bin/bash -c "xargs -0a /tmp/args.txt '$realdocker'"
          winpty /bin/bash -c "xargs -0a /tmp/args.txt '$realdocker'"
          return 0
      fi
  fi
  docker "$@"
  return 0
}

# sast
function sast(){
  base_dir="$2"
  [ -z "$base_dir" ] && raise_error "Directory to scan is missing"
  if [[ -t 0 ]]; then IT+=(-i); fi
  if [[ -t 1 ]]; then IT+=(-t); fi
  _docker run --rm "${IT[@]}" -e "WORKSPACE=${base_dir}" -v $base_dir:/app rajasoun/sast:1.1 scan --build

}

# sbom-scan
function sbom_scan(){
  base_dir="$2"
  [ -z "$base_dir" ] && raise_error "Directory to scan is missing"
  if [[ -t 0 ]]; then IT+=(-i); fi
  if [[ -t 1 ]]; then IT+=(-t); fi
  echo -e "Scanning $base_dir"
  _docker run --rm "${IT[@]}" -v "${base_dir}:/scan-dir" rajasoun/sbom-scan:1.1
  rm -fr $base_dir/sbom.json
}


# stops apps and clean logs
function clean(){
  echo -e "Deleting Docker Images "
  docker rmi rajasoun/sbom-scan:1.1
  docker rmi rajasoun/sast:1.1
  rm -fr reports
}


# help 
function help(){
  echo -e "${RED}Usage: $0  { sbom-scan | sast | dast } ${NC}" >&2
  echo
  echo "   ${ORANGE}sbom-scan <dir> -> Software Bill of Material (SBOM) Scanner ${NC}"
  echo "   ${ORANGE}sast      <dir> -> Satic Application Security Test ${NC}"
  echo
  return 1
}

# main
function main(){
  check_pre_conditions
  opt="$1"
  choice=$( tr '[:upper:]' '[:lower:]' <<<"$opt" )
  case $choice in
    sast) sast  "$@" ;;
    sbom-scan) sbom_scan  "$@" ;;
    *)  help ;;
  esac
}

main "$@"

