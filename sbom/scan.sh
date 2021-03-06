#!/usr/bin/env bash

NC=$'\e[0m' # No Color
BOLD=$'\033[1m'
UNDERLINE=$'\033[4m'
RED=$'\e[31m'
GREEN=$'\e[32m'
BLUE=$'\e[34m'
ORANGE=$'\x1B[33m'

# raise error
function raise_error(){
  echo -e "${BOLD}${RED}${1}${NC}" >&2
  exit 1
}

# print git repository link. Exit if not git repository directory
function print_repo_details(){
    if git tag > /dev/null 2>&1; then
        repo_name=$(git ls-remote --get-url)
        echo -e "${BOLD}${ORANGE}Git Repository : ${NC}$repo_name\n"
    else
        echo -e "${BOLD}${RED}Not a Git Repository. ${NC}\n"
    fi
}


echo -e "${BOLD}${UNDERLINE}\nSBOM Generator & Vulnerability Scanner - v1.0${NC}\n"
print_repo_details
echo -e "\n1. Generating Software Bill of Materials(SBOM) for the Project"
syft packages . -o json > sbom.json
echo -e "\n2. Scanning Software Bill of Materials(SBOM) for All Vulnerabilities"
grype sbom:sbom.json 

echo -e "\n3. Vulnerabilities in Software Bill of Materials(SBOM)"
cat sbom.json | grype



