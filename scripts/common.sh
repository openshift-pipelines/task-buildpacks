#!/usr/bin/env bash

#
# Functions
#

function fail() {
    echo "ERROR: ${*}" 2>&1
    exit 1
}

function phase() {
    echo "---> Phase: ${*}..."
}

#
# Environment Variables
#

declare -rx PARAMS_APP_IMAGE="${PARAMS_APP_IMAGE:-}"
declare -rx PARAMS_BUILDER_IMAGE="${PARAMS_BUILDER_IMAGE:-}"
declare -rx PARAMS_CNB_PLATFORM_API="${PARAMS_CNB_PLATFORM_API:-}"
declare -rx PARAMS_SUBDIRECTORY="${PARAMS_SUBDIRECTORY:-}"
declare -rx PARAMS_PROCESS_TYPE="${PARAMS_PROCESS_TYPE:-}"
declare -rx PARAMS_BINDINGS_GLOB="${PARAMS_BINDINGS_GLOB:-}"
declare -rx PARAMS_RUN_IMAGE="${PARAMS_RUN_IMAGE:-}"
declare -rx PARAMS_CACHE_IMAGE="${PARAMS_CACHE_IMAGE:-}"
declare -rx PARAMS_SKIP_RESTORE="${PARAMS_SKIP_RESTORE:-}"
declare -rx PARAMS_USER_ID="${PARAMS_USER_ID:-}"
declare -rx PARAMS_GROUP_ID="${PARAMS_GROUP_ID:-}"
declare -rx PARAMS_VERBOSE="${PARAMS_VERBOSE:-}"

declare -rx WORKSPACES_SOURCE_PATH="${WORKSPACES_SOURCE_PATH:-}"
declare -rx WORKSPACES_CACHE_BOUND="${WORKSPACES_CACHE_BOUND:-}"
declare -rx WORKSPACES_CACHE_PATH="${WORKSPACES_CACHE_PATH:-}"
declare -rx WORKSPACES_BINDINGS_BOUND="${WORKSPACES_BINDINGS_BOUND:-}"
declare -rx WORKSPACES_BINDINGS_PATH="${WORKSPACES_BINDINGS_PATH:-}"

declare -rx RESULTS_APP_IMAGE_DIGEST_PATH="${RESULTS_APP_IMAGE_DIGEST_PATH:-}"
declare -rx RESULTS_APP_IMAGE_URL_PATH="${RESULTS_APP_IMAGE_URL_PATH:-}"

#
# Additional Configuration
#

# full path to the target application source code directory
declare -rx SOURCE_DIR="${WORKSPACES_SOURCE_PATH}/${PARAMS_SUBDIRECTORY}"

declare -rx TEKTON_HOME="${TEKTON_HOME:-/tekton/home}"

# common buildpacks configuration directories
declare -x CNB_LOG_LEVEL="info"
declare -rx PLATFORM_ENV_DIR="${PLATFORM_ENV_DIR:-/platform/env}"
declare -rx LAYERS_DIR="${LAYERS_DIR:-/layers}"
declare -rx SERVICE_BINDING_ROOT="${SERVICE_BINDING_ROOT:-/bindings}"
declare -rx REPORT_TOML_PATH="${REPORT_TOML_PATH:-${LAYERS_DIR}/report.toml}"

#
# Asserting Environment
#

declare -ra required_vars=(
    WORKSPACES_SOURCE_PATH
    PARAMS_APP_IMAGE
    RESULTS_APP_IMAGE_DIGEST_PATH
    RESULTS_APP_IMAGE_URL_PATH
)

for v in "${required_vars[@]}"; do
    [[ -z "${!v}" ]] &&
        fail "'${v}' environment variable is not set!"
done

#
# Settings
#

# making sure the lifecycle directory is present on the path
[[ -d "/cnb/lifecycle" ]] && export PATH="${PATH}:/cnb/lifecycle"

if [[ "${PARAMS_VERBOSE}" == "true" ]]; then
    export CNB_LOG_LEVEL="debug"
    set -x
fi
