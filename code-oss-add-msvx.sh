#!/bin/sh

# Add microsoft marketplace to code-oss

main() {
    set -e

    PRODUCT_WITH_PLATFORM="VSCode-linux-x64"
    if [ "${OSTYPE}" = "msys" ] || [ "${OSTYPE}" = "cygwin" ]
    then
        PRODUCT_WITH_PLATFORM="VSCode-win32-x64"
    fi
    PRODUCT_JSON_FILE="${PRODUCT_WITH_PLATFORM}/resources/app/product.json"
    PATCHED="marketplace.visualstudio.com"
    if ! grep -q ${PATCHED} ${PRODUCT_JSON_FILE}
    then
        sed -i '$s+}+,\n"extensionsGallery": {\n"serviceUrl": "https://marketplace.visualstudio.com/_apis/public/gallery",\n"cacheUrl": "https://vscode.blob.core.windows.net/gallery/index",\n"itemUrl": "https://marketplace.visualstudio.com/items"\n}\n}+' ${PRODUCT_JSON_FILE}
    fi
}

# Main procedure
main
