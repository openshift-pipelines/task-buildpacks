#!/usr/bin/env bash
#
# Preparation step before running the buildpacks CNB.
#

shopt -s inherit_errexit
set -eu -o pipefail

source "$(dirname ${BASH_SOURCE[0]})/common.sh"

# script arguments for passing environment varible key-value pairs (split by equal sign)
declare -ra args=(${@})

#
# Workspaces Ownership
#

phase "Preparing the Workspaces, setting the expected ownership and permissions"

# list of directories needed by the cnb
declare -a cnb_dirs=(${LAYERS_DIR} ${WORKSPACES_SOURCE_PATH})

# when the cache workspace is bound, adding to the list of directories
[[ "${WORKSPACES_CACHE_BOUND}" == "true" ]] &&
    cnb_dirs+=(${WORKSPACES_CACHE_PATH})

for d in ${cnb_dirs[@]}; do
    phase "Changing ownership of '${d}' ('${PARAMS_USER_ID}:${PARAMS_GROUP_ID}')"
    chown -Rv "${PARAMS_USER_ID}:${PARAMS_GROUP_ID}" "${d}"
done

chmod -v 775 "${WORKSPACES_SOURCE_PATH}"

#
# CNB Environment Variables
#

# environment variables expected to be included on the container image built by the cnb must be
# defined as files on the "/platform/env" directory
if [[ ! -d "${PLATFORM_ENV_DIR}" ]]; then
    phase "Creating directory '${PLATFORM_ENV_DIR}'"
    mkdir -v -p "${PLATFORM_ENV_DIR}"
fi

# reading the array of arguments given to this script as key-value pairs, split by equal sign, and
# using these to create files, following the buildpacks convention the key becomes the file name and
# the value its contents
for kv in "${args[@]}"; do
    IFS='=' read -r key value <<<"${kv}"
    if [[ -n "${key}" ]]; then
        file_path="${PLATFORM_ENV_DIR}/${key}"
        phase "Creating environment file '${file_path}'"
        printf "%s" "${value}" >"${file_path}"
    fi
done

#
# Extra Bindings
#

# copying the files described on the paramater to the service-binding directory, that allows the cnb
# to embed the certificate bundles on the final container image
if [[ "${WORKSPACES_BINDINGS_BOUND}" == "true" ]]; then
    phase "Preparing buildpacks bindings '${SERVICE_BINDING_ROOT}'"

    [[ ! -d "${SERVICE_BINDING_ROOT}" ]] &&
        mkdir -v -p ${SERVICE_BINDING_ROOT}

    [[ -z "${PARAMS_BINDINGS_GLOB}" ]] &&
        fail "BINDINGS_GLOB is not informed while bindings Workspace is mounted!"

    phase "Searching for '${PARAMS_BINDINGS_GLOB}' on bindins workspace"
    for f in $(find ${WORKSPACES_BINDINGS_PATH} -name "${PARAMS_BINDINGS_GLOB}"); do
        phase "Copying binding '${f}' to '${SERVICE_BINDING_ROOT}'"
        cp -v ${f} ${SERVICE_BINDING_ROOT}
    done
fi
