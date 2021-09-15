#!/usr/bin/env bash

set -e

function build_dockerfile {
    DOCKERFILE_HEADER="$(<.devcontainer/code-in-container/Dockerfile.package_downloader)"
    DOCKERFILE_BUILD_PACKAGES="# Build package containers"
    DOCKERFILE_PACKAGE_ARGS=""
    DOCKERFILE_INSTALL_PACKAGES="# Install package contents"
    DOCKERFILE_ARG_VALUES=""
    APT_PACKAGES=""

    while IFS=$'\t' read -r _source PACKAGE_ORDER PACKAGE_NAME PACKAGE_VERSION; do
        echo "source: ${_source?} order: ${PACKAGE_ORDER?} package: ${PACKAGE_NAME?} version: ${PACKAGE_VERSION?}"

        if ! [[ "${PACKAGE_NAME?}" =~ ^[0-9a-zA-Z]+(-[0-9a-zA-Z]+)*$ ]]; then
            echo "The package name '${PACKAGE_NAME?}' is not currently supported."
            return 1
        fi

        if ! [[ "${PACKAGE_ORDER?}" =~ ^[0-9]+$ ]]; then
            echo "The package order '${PACKAGE_ORDER?}' used for ${PACKAGE_NAME?} is not currently supported."
            return 1
        fi

        case ${_source?} in
        _)
            if ! [[ "${PACKAGE_VERSION?}" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
                echo "The package version '${PACKAGE_VERSION?}' used for ${PACKAGE_NAME?} is not currently supported."
                return 1
            fi
            _package_path=".devcontainer/code-in-container/code-packages/${PACKAGE_NAME?}"
            if [[ ! -d "${_package_path}" ]]; then
                _package_path=".devcontainer/code-packages/${PACKAGE_NAME?}"
            fi
            if [[ ! -d "${_package_path}" ]]; then
                echo "Could not find package path for ${PACKAGE_NAME?}."
                return 1
            fi

            _package_dockerfile="${_package_path?}/Dockerfile.package"
            _package_post_install="${_package_path?}/docker.post_install"
            _package_variable="$(tr [:lower:] [:upper:] <<<${PACKAGE_NAME?})"

            if [[ ! -f "${_package_dockerfile?}" ]]; then
                echo "A Dockerfile was not found at ${_package_dockerfile?}."
                return 1
            fi

            DOCKERFILE_ARG_VALUES="${DOCKERFILE_ARG_VALUES?}"$'\n'"ARG ${_package_variable?}_VERSION=${PACKAGE_VERSION?}"
            DOCKERFILE_ARG_VALUES="${DOCKERFILE_ARG_VALUES?}"$'\n'"ARG ${_package_variable?}_ORDER=${PACKAGE_ORDER?}"
            DOCKERFILE_BUILD_PACKAGES="${DOCKERFILE_BUILD_PACKAGES?}"$'\n\n'"# Build ${PACKAGE_NAME?} ${PACKAGE_VERSION?} package"
            DOCKERFILE_BUILD_PACKAGES="${DOCKERFILE_BUILD_PACKAGES?}"$'\n\n'"$(<${_package_dockerfile?})"
            DOCKERFILE_PACKAGE_ARGS="${DOCKERFILE_PACKAGE_ARGS?}"$'\n'"ARG ${_package_variable?}_VERSION"$'\n'"ARG ${_package_variable?}_ORDER"
            DOCKERFILE_INSTALL_PACKAGES="${DOCKERFILE_INSTALL_PACKAGES?}"
            DOCKERFILE_INSTALL_PACKAGES="${DOCKERFILE_INSTALL_PACKAGES?}"$'\n\n'"$(
                cat <<END
COPY --from=${PACKAGE_NAME?}_package /package /package
RUN rsync -a /package/ / && rm -rf /package
END
            )"
            if [[ -f "${_package_post_install?}" ]]; then
                DOCKERFILE_INSTALL_PACKAGES="${DOCKERFILE_INSTALL_PACKAGES?}"$'\n'"$(<${_package_post_install?})"
            fi
            ;;
        apt)
            if ! [[ "${PACKAGE_VERSION?}" =~ ^_$ ]]; then
                echo "The package version '${PACKAGE_VERSION?}' used for ${PACKAGE_NAME?} is not currently supported."
                return 1
            fi

            APT_PACKAGES="${APT_PACKAGES?} ${PACKAGE_NAME?}"
            ;;
        *)
            echo "The source '${_source?}' used for ${PACKAGE_NAME?} is not currently supported."
            return 1
            ;;
        esac
    done <.devcontainer/code-in-container.tsv

    DOCKERFILE="${DOCKERFILE_ARG_VALUES?}"$'\n\n'"${DOCKERFILE_HEADER?}"
    DOCKERFILE="${DOCKERFILE?}"$'\n\n'"${DOCKERFILE_BUILD_PACKAGES?}"
    DOCKERFILE="${DOCKERFILE?}"$'\n\n'"$(<.devcontainer/code-in-container/Dockerfile.docker_in_docker)"
    DOCKERFILE="${DOCKERFILE?}"$'\n\n'"$(<.devcontainer/code-in-container/Dockerfile.devcontainer)"
    DOCKERFILE="${DOCKERFILE?}"$'\n'"${DOCKERFILE_PACKAGE_ARGS?}"

    if [[ "${APT_PACKAGES?}x" != "x" ]]; then
        DOCKERFILE="${DOCKERFILE?}"$'\n\n'"$(
            cat <<END
# Install apt packages

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive && apt-get -y install --no-install-recommends${APT_PACKAGES}
END
        )"
    fi

    DOCKERFILE="${DOCKERFILE?}"$'\n\n'"${DOCKERFILE_INSTALL_PACKAGES?}"
    echo "${DOCKERFILE?}" | tee .devcontainer/Dockerfile
}

build_dockerfile
