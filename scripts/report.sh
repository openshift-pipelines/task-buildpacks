#!/usr/bin/env bash
#
# Inspects the `/layers/report.toml` to extract attributes about the image built by the CNB, and use
# the data to write the expected Tekton result files.
#

shopt -s inherit_errexit
set -eu -o pipefail

source "$(dirname ${BASH_SOURCE[0]})/common.sh"

phase "Making sure report file exists '${REPORT_TOML_PATH}'"
[[ ! -f "${REPORT_TOML_PATH}" ]] &&
	fail "Report file is not found at 'REPORT_TOML_PATH=${REPORT_TOML_PATH}'!"

#
# Extracting Image Details
#

phase "Extracting result image digest and URL"

readonly digest="$(awk -F '"' '/digest/ { print $2 }' ${REPORT_TOML_PATH})"
readonly image_tag="$(awk -F '"' '/tags/ { print $2 }' ${REPORT_TOML_PATH})"

phase "Writing image digest '${digest}' to '${RESULTS_IMAGE_DIGEST_PATH}'"
printf "%s" "${digest}" >${RESULTS_IMAGE_DIGEST_PATH}

phase "Writing image URL '${image_tag}' to '${RESULTS_IMAGE_URL_PATH}'"
printf "%s" "${image_tag}" >${RESULTS_IMAGE_URL_PATH}
