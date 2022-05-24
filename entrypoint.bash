#!/bin/bash

set -x

if [[ "${OSTYPE}" == "cygwin" || "${OSTYPE}" == "msys" ]]; then
  PLATFORM_FLAVOR="win32-x64"
  npm install --global yarn
else
  PLATFORM_FLAVOR="linux-x64"
fi
TARGET_DIR_NAME="VSCode-${PLATFORM_FLAVOR}"

rm -rf ${HOME}/${TARGET_DIR_NAME}
rm -rf ${HOME}/*.tar.gz

VSCODE="vscode"
if [ ! -d "${HOME}/${VSCODE}/.git" ]; then
   cd ${HOME}
   git clone https://github.com/microsoft/${VSCODE}.git
   cd ${HOME}/${VSCODE}/
else
   cd ${HOME}/${VSCODE}/
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

cd ${HOME}
tar -I 'gzip -9' -chf ./${TARGET_DIR_NAME}-${TOP_TAG}.tar.gz ./${TARGET_DIR_NAME}
