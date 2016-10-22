#!/bin/bash
# Copyright (c) 2012-2016 Codenvy, S.A.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#   Tyler Jewell - Initial Implementation
#

init_logging() {
  BLUE='\033[1;34m'
  GREEN='\033[0;32m'
  RED='\033[0;31m'
  YELLOW='\033[38;5;220m'
  NC='\033[0m'

  # Which che CLI version to run?
  DEFAULT_CHE_CLI_VERSION="latest"
  CHE_CLI_VERSION=${CHE_CLI_VERSION:-${DEFAULT_CHE_CLI_VERSION}}

  DEFAULT_CHE_PRODUCT_NAME="CODENVY"
  CHE_PRODUCT_NAME=${CHE_PRODUCT_NAME:-${DEFAULT_CHE_PRODUCT_NAME}}

  # Name used in CLI statements
  DEFAULT_CHE_MINI_PRODUCT_NAME="codenvy"
  CHE_MINI_PRODUCT_NAME=${CHE_MINI_PRODUCT_NAME:-${DEFAULT_CHE_MINI_PRODUCT_NAME}}

  # Turns on stack trace
  DEFAULT_CHE_CLI_DEBUG="false"
  CHE_CLI_DEBUG=${CHE_CLI_DEBUG:-${DEFAULT_CHE_CLI_DEBUG}}

  # Activates console output
  DEFAULT_CHE_CLI_INFO="true"
  CHE_CLI_INFO=${CHE_CLI_INFO:-${DEFAULT_CHE_CLI_INFO}}

  # Activates console warnings
  DEFAULT_CHE_CLI_WARN="true"
  CHE_CLI_WARN=${CHE_CLI_WARN:-${DEFAULT_CHE_CLI_WARN}}
}

warning() {
  if is_warning; then
    printf  "${YELLOW}WARN:${NC} %s\n" "${1}"
  fi
}

info() {
  if is_info; then
    if [ -z ${2+x} ]; then 
      PRINT_COMMAND=""
      PRINT_STATEMENT=$1
    else
      PRINT_COMMAND="($CHE_MINI_PRODUCT_NAME $1):"
      PRINT_STATEMENT=$2
    fi
    printf "${GREEN}INFO:${NC} %s %s\n" \
              "${PRINT_COMMAND}" \
              "${PRINT_STATEMENT}"
  fi
}

debug() {
  if is_debug; then
    printf  "\n${BLUE}DEBUG:${NC} %s" "${1}"
  fi
}

error() {
  printf  "${RED}ERROR:${NC} %s\n" "${1}"
}

is_warning() {
  if [ "${CHE_CLI_WARN}" = "true" ]; then
    return 0
  else
    return 1
  fi
}

is_info() {
  if [ "${CHE_CLI_INFO}" = "true" ]; then
    return 0
  else
    return 1
  fi
}

is_debug() {
  if [ "${CHE_CLI_DEBUG}" = "true" ]; then
    return 0
  else
    return 1
  fi
}

has_docker() {
  hash docker 2>/dev/null && return 0 || return 1
}

has_curl() {
  hash curl 2>/dev/null && return 0 || return 1
}

check_docker() {
  if ! has_docker; then
    error "Error - Docker not found. Get it at https://docs.docker.com/engine/installation/."
    return 1;
  fi

  if ! docker ps > /dev/null 2>&1; then
    output=$(docker ps)
    error "Error - Docker not installed properly: \n${output}"
    return 1;
  fi

  # Prep script by getting default image
  if [ "$(docker images -q alpine 2> /dev/null)" = "" ]; then
    info "cli" "Pulling image alpine:latest"
    docker pull alpine > /dev/null 2>&1
  fi

  if [ "$(docker images -q appropriate/curl 2> /dev/null)" = "" ]; then
    info "cli" "Pulling image curl:latest"
    docker pull appropriate/curl > /dev/null 2>&1
  fi

  if [ "$(docker images -q codenvy/che-ip:nightly 2> /dev/null)" = "" ]; then
    info "cli" "Pulling image codenvy/che-ip:nightly"
    docker pull codenvy/che-ip:nightly > /dev/null 2>&1
  fi

  if [ "$(docker images -q codenvy/version 2> /dev/null)" = "" ]; then
    info "cli" "Pulling image codenvy/version"
    docker pull codenvy/version > /dev/null 2>&1
  fi
}

curl() {
  if ! has_curl; then
    docker run --rm --net=host appropriate/curl "$@"
  else
    $(which curl) "$@"
  fi
}

update_cli() {
  info "cli" "Downloading cli-$CHE_CLI_VERSION"

  CLI_DIR=~/."${CHE_MINI_PRODUCT_NAME}"/cli
  test -d "${CLI_DIR}" || mkdir -p "${CLI_DIR}"

  if [[ "${CHE_CLI_VERSION}" = "latest" ]] || \
     [[ "${CHE_CLI_VERSION}" = "nightly" ]] || \
     [[ ${CHE_CLI_VERSION:0:1} == "4" ]]; then
    GITHUB_VERSION=master
  else
    GITHUB_VERSION=$CHE_CLI_VERSION
  fi

  # If the codenvy.sh is running from the codenvy source repo, then always use cli.sh that is there 
  if [[ $(get_script_source_dir) != ~/."${CHE_MINI_PRODUCT_NAME}"/cli ]]; then  
    cp -rf $(get_script_source_dir)/cli.sh ~/."${CHE_MINI_PRODUCT_NAME}"/cli/cli-$CHE_CLI_VERSION.sh
    return
  fi

  # We are downloading the CLI from the core repository.
  URL=https://raw.githubusercontent.com/codenvy/codenvy/$GITHUB_VERSION/cli.sh

  if ! curl --output /dev/null --silent --head --fail "$URL"; then
    error "CLI download error. Bad network or version."
    return 1;
  else 
    curl -sL $URL > ~/."${CHE_MINI_PRODUCT_NAME}"/cli/cli-$CHE_CLI_VERSION.sh
  fi
}

get_script_source_dir() {
  SOURCE="${BASH_SOURCE[0]}"
  while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  done
  echo "$( cd -P "$( dirname "$SOURCE" )" && pwd )"
}

init() {
  init_logging
  check_docker

  # Test to see if we have cli_funcs
  if [[ ! -f ~/."${CHE_MINI_PRODUCT_NAME}"/cli/cli-${CHE_CLI_VERSION}.sh ]] ||
     [[ $(get_script_source_dir)/cli.sh -nt ~/."${CHE_MINI_PRODUCT_NAME}"/cli/cli-${CHE_CLI_VERSION}.sh ]]; then
    update_cli
  fi

  source ~/."${CHE_MINI_PRODUCT_NAME}"/cli/cli-${CHE_CLI_VERSION}.sh
}

# See: https://sipb.mit.edu/doc/safe-shell/
set -e
set -u

# Initialize the self-updating CLI - this is a common code between Che & Codenvy.
init

# Begin product-specific CLI calls
cli_init "$@"
cli_parse "$@"
cli_cli "$@"