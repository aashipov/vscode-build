#!/bin/bash

set -x

# Take n retries till zero exit code or n is expired
# https://serverfault.com/a/1058764
retry() {
  local retries_count=5
  local sleep_between_retries_for=5s
  local command="${*}"
  local retval=1
  local attempt=1
  until [[ ${retval} -eq 0 ]] || [[ ${attempt} -gt ${retries_count} ]]; do
    # Execute inside of a subshell in case parent
    # script is running with "set -e"
    (
      set +e
      ${command}
    )
    retval=${?}
    attempt=$((${attempt} + 1))
    if [[ ${retval} -ne 0 ]]; then
      # If there was an error wait ... seconds
      sleep ${sleep_between_retries_for}
    fi
  done
  if [[ ${retval} -ne 0 ]] && [[ ${attempt} -gt ${retries_count} ]]; then
    # Something is fubar, go ahead and exit
    echo "command ${command} failed with exit code ${retval}"
  fi
}

environment() {
  export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
  export NODE_OPTIONS="--max-old-space-size=8192"
  
  local _SCRIPT_DIR=$(dirname -- "$(readlink -f -- "$0")")

  TAG_TO_BUILD=$(cat ${_SCRIPT_DIR}/.tag_to_build)
  if [[ "${TAG_TO_BUILD}" == "" ]]; then
    printf "Can not find ${_SCRIPT_DIR}/.tag_to_build file or it is empty\n"
    exit 1
  fi

  VSCODE=vscode
  local BUILDBED_DIR_NAME=${VSCODE}-buildbed

  PLATFORM_FLAVOR="linux-x64"
  TOP_DIR=${HOME}/${BUILDBED_DIR_NAME}
  if [[ "${OSTYPE}" == "cygwin" || "${OSTYPE}" == "msys" ]]; then
    PLATFORM_FLAVOR="win32-x64"
  fi
  if [[ "${OSTYPE}" == "cygwin" ]]; then
    TOP_DIR="/cygdrive/c/${BUILDBED_DIR_NAME}"
  fi
  if [[ "${OSTYPE}" == "msys" ]]; then
    TOP_DIR="/c/${BUILDBED_DIR_NAME}"
  fi
  TARGET_DIR_NAME="VSCode-${PLATFORM_FLAVOR}"
}

clean_leftovers() {
  mkdir -p ${TOP_DIR}
  rm -rf ${TOP_DIR}/${TARGET_DIR_NAME}
  rm -rf ${TOP_DIR}/*.tar.gz
}

checkout() {
  local DEFAULT_BRANCH=main
  if [ ! -d "${TOP_DIR}/${VSCODE}/.git" ]; then
    cd ${TOP_DIR}
    git clone https://github.com/microsoft/${VSCODE}.git
    cd ${TOP_DIR}/${VSCODE}/
  else
    cd ${TOP_DIR}/${VSCODE}/
    find "${PWD}" -type d -name 'node_modules' -exec rm -r {} \;
    git reset --hard
    git checkout ${DEFAULT_BRANCH}
    git pull --rebase
    git fetch --tags -f
  fi

  if [ $(git tag -l "${TAG_TO_BUILD}") ]; then
    git clean -d -f .
    git checkout tags/${TAG_TO_BUILD}
  else
    printf "Can not find tag ${TAG_TO_BUILD}\n"
    exit 1
  fi
}

install_node_headers(){
	cd ${TOP_DIR}/${VSCODE}/
	local NODE_HEADERS_VERSION=$(grep -E "\"electron\": \"[[:digit:]]." package.json | cut -d '"' -f 4)
	curl -LO https://www.electronjs.org/headers/v${NODE_HEADERS_VERSION}/node-v${NODE_HEADERS_VERSION}-headers.tar.gz 
	npm_config_tarball=${TOP_DIR}/${VSCODE}/node-v${NODE_HEADERS_VERSION}-headers.tar.gz npm install
}

build() {
  set -e
  cd ${TOP_DIR}/${VSCODE}/
  if [ [ -f /etc/centos-release ] || [ -f /etc/redhat-release ] ] && [ ! -f /etc/fedora-release ]; then
    source /opt/rh/devtoolset-10/enable
  fi

  npm install
  npm run monaco-compile-check
  npm run valid-layers-check

  npm run compile-build
  npm run gulp compile-extension-media
  retry npm run compile-extensions-build
  npm run minify-vscode
  npm run gulp vscode-${PLATFORM_FLAVOR}-min-ci
}

publish() {
  if [[ $? -eq 0 ]]; then
    cd ${TOP_DIR}
    FILE_NAME=${TARGET_DIR_NAME}-${TAG_TO_BUILD}.tar.gz
    GZIP=-9 tar -czhf ${FILE_NAME} ${TARGET_DIR_NAME}

    GITHUB_TOKEN=$(cat ${HOME}/.github_token)
    if [[ "${GITHUB_TOKEN}" != "" ]]; then
      GITHUB_OWNER=aashipov
      GITHUB_REPO=vscode-build
      GITHUB_RELEASE_ID=77065247

      curl \
        https://uploads.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/releases/${GITHUB_RELEASE_ID}/assets?name=${FILE_NAME} \
        -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        -H "Content-type: application/gzip" \
        --data-binary @${TOP_DIR}/${FILE_NAME}
    fi
  fi
}

closure() {
  if [[ "${OSTYPE}" == "cygwin" ]]; then
    printf "Will not compile with cygwin. Switch to Git Bash\n"
    exit 1
  fi
  environment
  clean_leftovers
  checkout
  install_node_headers
  build
  publish
}

# Main procedure
closure
