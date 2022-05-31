#!/bin/bash

set -x

PLATFORM_FLAVOR="linux-x64"
TOP_DIR=${HOME}
if [[ "${OSTYPE}" == "cygwin" || "${OSTYPE}" == "msys" ]]; then
  PLATFORM_FLAVOR="win32-x64"
  npm install --global yarn
  TOP_DIR="/cygdrive/c"
fi
TARGET_DIR_NAME="VSCode-${PLATFORM_FLAVOR}"

rm -rf ${TOP_DIR}/${TARGET_DIR_NAME}
rm -rf ${TOP_DIR}/*.tar.gz

VSCODE="vscode"
if [ ! -d "${TOP_DIR}/${VSCODE}/.git" ]; then
  cd ${TOP_DIR}
  git clone https://github.com/microsoft/${VSCODE}.git
  cd ${TOP_DIR}/${VSCODE}/
else
  cd ${TOP_DIR}/${VSCODE}/
  find "${PWD}" -type d -name 'node_modules' -exec rm -r {} \;
  git reset --hard
  git checkout main
  git pull --rebase
fi

# https://gist.github.com/rponte/fdc0724dd984088606b0 or commit sha
TOP_TAG=$(git describe --tags $(git rev-list --tags --max-count=1))
git checkout ${TOP_TAG}

if [[ "$(uname)" == "CYGWIN_NT-6.3-9600" ]]; then
  dotnet tool install --global PowerShell
  pwsh -c yarn
else
  yarn
fi
yarn gulp vscode-${PLATFORM_FLAVOR}-min

cd ${TOP_DIR}
GZIP=-9 tar -czhf ./${TARGET_DIR_NAME}-${TOP_TAG}.tar.gz ./${TARGET_DIR_NAME}
