#!/bin/bash

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
  #export ELECTRON_SKIP_BINARY_DOWNLOAD=1
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
  if [[ "${OSTYPE}" == "msys" ]]; then
    PLATFORM_FLAVOR="win32-x64"
    TOP_DIR="/c/${BUILDBED_DIR_NAME}"
  fi
  TARGET_DIR_NAME="VSCode-${PLATFORM_FLAVOR}"
}

clean_npm_and_node-gyp() {
  if [[ "${OSTYPE}" == "msys" ]]; then
    rm -rf ${USERPROFILE}/AppData/Local/npm-cache
    rm -rf ${USERPROFILE}/AppData/Local/node-gyp
  else
    rm -rf ${HOME}/.npm/
    rm -rf ${HOME}/.cache/node-gyp/
  fi
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
    git clean -xfd
    git reset --hard
    git checkout ${DEFAULT_BRANCH}
    git pull --rebase
    git fetch --tags -f
  fi

  if [ $(git tag -l "${TAG_TO_BUILD}") ]; then
    git checkout tags/${TAG_TO_BUILD}
  elif [[ $(git cat-file -t ${TAG_TO_BUILD}) == "commit" ]]; then
    git checkout ${TAG_TO_BUILD}
  else
    TAG_TO_BUILD=${DEFAULT_BRANCH}-$(git rev-parse --short HEAD)
    printf "Will build ${TAG_TO_BUILD} \n"
  fi
}

build() {
  cd ${TOP_DIR}/${VSCODE}/

  set +e
  retry npm ci
  set -e

  export NODE_OPTIONS="--max-old-space-size=8192"

  npm run monaco-compile-check
  npm run valid-layers-check

  npm run gulp compile-build-without-mangling
  npm run gulp compile-extension-media
  npm run gulp compile-extensions-build

  set +e
  retry npm run compile-extensions-build
  set -e

  npm run minify-vscode
  npm run gulp vscode-${PLATFORM_FLAVOR}-min-ci
}

publish() {
  if [[ $? -eq 0 ]]; then
    cd ${TOP_DIR}
    local FILE_NAME=${TARGET_DIR_NAME}-${TAG_TO_BUILD}.tar.gz
    
    GZIP=-9 tar -czhf ${FILE_NAME} ${TARGET_DIR_NAME}

    local GITHUB_TOKEN=$(cat ${HOME}/.github_token)
    if [[ "${GITHUB_TOKEN}" != "" ]]; then
      local GITHUB_OWNER=aashipov
      local GITHUB_REPO=vscode-build
      local GITHUB_RELEASE_ID=77065247

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
  #clean_npm_and_node-gyp
  clean_leftovers
  checkout
  build
  publish
}

# Main procedure
closure
