#!/bin/sh

retry() {
    retries_count=3
    sleep_between_retries_for=5s
    command="${*}"
    retval=1
    while :
    do
        retries_count=$((retries_count - 1))

        if [ ${retries_count} -eq -1 ]
        then
            break
        fi
        ${command}
        retval=${?}
        if [ ${retval} -eq 0 ]
        then
            break
        fi
        sleep ${sleep_between_retries_for}
    done
    if [ ${retval} -ne 0 ]
    then
        printf 'Command %s failed with exit code %s\n' "${command}" "${retval}"
    fi
    unset retries_count sleep_between_retries_for command retval
}


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

environment() {
    BASE_DIR="$(get_base_dir)"

    ENV_FILE="${BASE_DIR}/.env"
    if [ ! -e "${ENV_FILE}" ]
    then
        die "No ${ENV_FILE} file found"
    fi
    # allexport .env
    case "${-}" in
        *a*)
            HAD_A=1
            ;;
        *)
            HAD_A=0
            set -a
            ;;
    esac
    # source: not found workaround
    . "${ENV_FILE}"
    [ "${HAD_A}" -eq 0 ] && set +a
    # allexport .env
    unset ENV_FILE HAD_A

    if [ -z "${TAG_TO_BUILD}" ]
    then
        printf 'TAG_TO_BUILD not set\n'
        exit 1
    fi

    PLATFORM_FLAVOR="linux-x64"
    TOP_DIR="${HOME}/${BUILDBED_DIR_NAME}"
    if [ "${OSTYPE}" = "msys" ] || [ "${OSTYPE}" = "cygwin" ]
    then
        PLATFORM_FLAVOR="win32-x64"
        TOP_DIR="/c/${BUILDBED_DIR_NAME}"
    fi
    TARGET_DIR_NAME="VSCode-${PLATFORM_FLAVOR}"
}

clean_npm_and_node_gyp() {
    if [ "${OSTYPE}" = "msys" ] || [ "${OSTYPE}" = "cygwin" ]
    then
        rm -rf "${USERPROFILE}/AppData/Local/npm-cache"
        rm -rf "${USERPROFILE}/AppData/Local/node-gyp"
    else
        rm -rf "${HOME}/.npm/"
        rm -rf "${HOME}/.cache/node-gyp/"
    fi
}

clean_leftovers() {
    mkdir -p "${TOP_DIR}"
    rm -rf "${TOP_DIR}/${TARGET_DIR_NAME}"
    rm -rf "${TOP_DIR}/*.tar.gz"
}

checkout() {
    DEFAULT_BRANCH=main
    if [ ! -d "${TOP_DIR}/${VSCODE}/.git" ]; then
        cd ${TOP_DIR}
        git clone "https://github.com/microsoft/${VSCODE}.git"
        cd "${TOP_DIR}/${VSCODE}/"
    else
        cd "${TOP_DIR}/${VSCODE}/"
        git clean -xfd
        git reset --hard
        git checkout "${DEFAULT_BRANCH}"
        git pull --rebase
        git fetch --tags -f
    fi

    if [ $(git tag -l "${TAG_TO_BUILD}") ]
    then
        git checkout "tags/${TAG_TO_BUILD}"
    elif [ "$(git cat-file -t ${TAG_TO_BUILD})" == "commit" ]
    then
        git checkout "${TAG_TO_BUILD}"
    elif printf -- '%s' "${TAG_TO_BUILD}" | grep -q -- "release"
    then
        git switch "${TAG_TO_BUILD}"
        git pull -r
    else
        TAG_TO_BUILD="${DEFAULT_BRANCH}-$(git rev-parse --short HEAD)"
        printf "Will build ${TAG_TO_BUILD} \n"
    fi
}

build() {
    cd "${TOP_DIR}/${VSCODE}/"
    retry npm install
    npm run gulp "vscode-${PLATFORM_FLAVOR}-min"
    if [ ! -d "${TOP_DIR}/${TARGET_DIR_NAME}" ]
    then
        npm run gulp "vscode-${PLATFORM_FLAVOR}-min"
    fi
}

publish() {
    if [ ${?} -eq 0 ]
    then
        cd ${TOP_DIR}
        TAG_TO_BUILD="$(printf -- '%s' "${TAG_TO_BUILD}" | tr '/' '-' )"
        FILE_NAME="${TARGET_DIR_NAME}-${TAG_TO_BUILD}.tar.gz"

        tar -chf "${FILE_NAME}" -I 'gzip -9' "${TARGET_DIR_NAME}"

        GITHUB_TOKEN="$(cat ${HOME}/.github_token)"
        if [ -n "${GITHUB_TOKEN}" ]
        then
            GITHUB_OWNER=aashipov
            GITHUB_REPO=vscode-build
            GITHUB_RELEASE_ID=77065247

            curl \
            "https://uploads.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/releases/${GITHUB_RELEASE_ID}/assets?name=${FILE_NAME}" \
            -H "Authorization: Bearer ${GITHUB_TOKEN}" \
            -H "Content-type: application/gzip" \
            --data-binary @"${TOP_DIR}/${FILE_NAME}"
        fi
    fi
}

closure() {
    environment
    #clean_npm_and_node_gyp
    clean_leftovers
    checkout
    build
    publish
}

# Main procedure
closure
