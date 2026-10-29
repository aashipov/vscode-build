#!/bin/sh

# ------------------------------------------------------------
# Script/base dir
# ------------------------------------------------------------
get_base_dir() {
    if [ -f "${0}" ]
    then
        # $0 points to a file on disk
        printf '%s\n' "$(cd -- "$(dirname -- "${0}")" && pwd -P)"
    else
        # The script was sourced in a shell where $0 is not the script path
        # Fallback to the current working directory
        printf '%s\n' "$(pwd -P)"
    fi
}

download() {
    printf 'Downloading %s to %s\n' "${SRC_URL}" "${TGT_FILE}"
    if ! curl -fL --retry 3 -o "${TGT_FILE}.part" "${SRC_URL}"
    then
        rm -f "${TGT_FILE}.part"
        printf 'Failed to download %s' "${SRC_URL}"
        exit 1
    fi
    mv "${TGT_FILE}.part" "${TGT_FILE}"
}

closure() {
    set -e
    BASE_DIR="$(get_base_dir)"
    cd "${BASE_DIR}"

    SRC_URL="https://raw.githubusercontent.com/aashipov/vscode-build/refs/heads/main/.env"
    TGT_FILE="${BASE_DIR}/code-oss.env"
    download
    TAG_TO_BUILD="$(cat ${TGT_FILE} | grep TAG_TO_BUILD | cut -d '=' -f 2)"

    PRODUCT_WITH_PLATFORM="VSCode-linux-x64"
    if [ "${OSTYPE}" = "msys" ] || [ "${OSTYPE}" = "cygwin" ]
    then
        PRODUCT_WITH_PLATFORM="VSCode-win32-x64"
    fi

    SRC_URL="https://github.com/aashipov/vscode-build/releases/latest/download/${PRODUCT_WITH_PLATFORM}-${TAG_TO_BUILD}.tar.gz"
    TGT_FILE="${BASE_DIR}/code-oss.tar.gz"
    download
    rm -rf "${BASE_DIR}/${PRODUCT_WITH_PLATFORM}"
    tar -xzf "${TGT_FILE}"

    SRC_URL="https://raw.githubusercontent.com/aashipov/vscode-build/refs/heads/main/code-oss-add-msvx.sh"
    TGT_FILE="${BASE_DIR}/code-oss-add-msvx.sh"
    download
    chmod +x "${TGT_FILE}"
    ${TGT_FILE}
}

closure
