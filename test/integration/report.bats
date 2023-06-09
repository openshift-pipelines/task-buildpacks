#!/usr/bin/env bats

source ./test/helper/helper.sh

report_sh="./scripts/report.sh"

export PARAMS_IMAGE="registry.local/namespace/project:latest"
export PARAMS_VERBOSE="true"

# asserting the script will error out when the environment is not complete
@test "[report.sh] should fail when the enviroment is incomplete" {
	unset WORKSPACES_SOURCE_PATH

	run ${report_sh}
	assert_failure
	assert_output --partial 'is not'
}

# running the report script against a mocked `report.yaml` file to assert it can extract the
# important bits and write it back on the expected locations
@test "[report.sh] should be able to extract image digest and fully qualified image name" {
	export WORKSPACES_SOURCE_PATH="${BASE_DIR}/workspace/source"

	export RESULTS_IMAGE_DIGEST_PATH="${BASE_DIR}/image-digest.txt"
	export RESULTS_IMAGE_URL_PATH="${BASE_DIR}/image-url.txt"

	export REPORT_TOML_PATH="./test/mock/report.toml"

	run ${report_sh}
	assert_success

	# making sure the result files tekton will read from are written and contain what's expected
	assert_file_contains ${RESULTS_IMAGE_DIGEST_PATH} "sha256:digest"
	assert_file_contains ${RESULTS_IMAGE_URL_PATH} "registry.local/namespace/project:latest"
}
