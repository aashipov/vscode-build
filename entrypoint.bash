#!/bin/bash

set -x

environment() {
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
    git checkout tags/${TAG_TO_BUILD}
  else
    printf "Can not find tag ${TAG_TO_BUILD}\n"
    exit 1
  fi
}

build() {
  set -e
  cd ${TOP_DIR}/${VSCODE}/
  if [ -f /etc/centos-release ] || [ -f /etc/redhat-release ]; then
    source /opt/rh/devtoolset-10/enable
  fi

  if [[ "${OSTYPE}" == "msys" ]]; then
    npm i -g yarn
    npm i -g gulp
    if [[ "$(uname)" == "MINGW64_NT-6.3-9600" ]]; then
      yarn cache clean
      # rm -rf ${USERPROFILE}/AppData/Local/node-gyp/
      # npm config -g set msvs_version 2017
      # npm i -g node-gyp@latest
      # npm config -g set node_gyp $(npm prefix -g)/node_modules/node-gyp/bin/node-gyp.js
      powershell -c yarn
    else
      powershell -c yarn
    fi
  else
    yarn
  fi
  yarn monaco-compile-check
  yarn valid-layers-check

  yarn gulp compile-build
  yarn gulp compile-extension-media
  yarn gulp compile-extensions-build
  yarn gulp minify-vscode
  yarn gulp vscode-${PLATFORM_FLAVOR}-min-ci
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
  build
  publish
}

# Main procedure
closure
