#!/usr/bin/env bash
#
# Runs the lifecycle "creator" command.
#

shopt -s inherit_errexit
set -eu -o pipefail

source "$(dirname ${BASH_SOURCE[0]})/common.sh"

phase "Inspecting source directory '${SOURCE_DIR}' (subdirectory '${PARAMS_SUBDIRECTORY}')"
[[ ! -d "${SOURCE_DIR}" ]] &&
	fail "application source directory '${SOURCE_DIR}' is not found!"

declare -rx CNB_PLATFORM_API="${PARAMS_CNB_PLATFORM_API}"

phase "Creating the image '${PARAMS_APP_IMAGE}' from '${SOURCE_DIR}' (API=${CNB_PLATFORM_API})"
set -x
exec creator \
	-app="${SOURCE_DIR}" \
	-process-type="${PARAMS_PROCESS_TYPE}" \
	-uid="${PARAMS_USER_ID}" \
	-gid="${PARAMS_GROUP_ID}" \
	-layers="/layers" \
	-platform="/platform" \
	-skip-restore="${PARAMS_SKIP_RESTORE}" \
	-cache-dir="${WORKSPACES_CACHE_PATH}" \
	-cache-image="${PARAMS_CACHE_IMAGE}" \
	-previous-image="${PARAMS_APP_IMAGE}" \
	-run-image="${PARAMS_RUN_IMAGE}" \
	-report="${REPORT_TOML_PATH}" \
	-log-level="${CNB_LOG_LEVEL}" \
	-no-color \
	${PARAMS_APP_IMAGE}
