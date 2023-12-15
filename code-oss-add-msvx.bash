#!/bin/bash

# Add microsoft marketplace to code-oss

main() {
    set -ex
    local VSCODE_DIR="VSCode-linux-x64"
    if [[ "${OSTYPE}" == "msys" ]]; then
       VSCODE_DIR="VSCode-win32-x64"
    fi
    local PRODUCT_JSON_FILE="${VSCODE_DIR}/resources/app/product.json"
    local PATCHED="marketplace.visualstudio.com"
    if ! grep -q ${PATCHED} ${PRODUCT_JSON_FILE}; then
        sed -i '$s+}+,\n"extensionsGallery": {\n"serviceUrl": "https://marketplace.visualstudio.com/_apis/public/gallery",\n"cacheUrl": "https://vscode.blob.core.windows.net/gallery/index",\n"itemUrl": "https://marketplace.visualstudio.com/items"\n}\n}+' ${PRODUCT_JSON_FILE}
    fi
}

# Main procedure
main
