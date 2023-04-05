#!/usr/bin/env bats

source ./test/helper/helper.sh

export PARAMS_APP_IMAGE="registry.local/namespace/project:latest"

export PARAMS_BINDINGS_GLOB="*.pem"
export PARAMS_GROUP_ID="$(id -g)"
export PARAMS_USER_ID="$(id -u)"

export PARAMS_VERBOSE="true"

prepare_sh="./scripts/prepare.sh"

# when there's no configuration, or the configuration is incomplete, the script must return error,
# this way we can assert it will run with all required configuration.
@test "[prepare.sh] should fail when the environment is incomplete" {
	unset WORKSPACES_SOURCE_PATH

	run ${prepare_sh}
	assert_failure
	assert_output --partial 'not set'
}

# asserging the script runs without the optional "cache" workspace.
@test "[prepare.sh] should be able to run prepare script without optional Workspaces" {
	[ -n "${BASE_DIR}" ]

	export TEKTON_HOME="${BASE_DIR}/tekton/home"
	export LAYERS_DIR="${BASE_DIR}/layers"
	export PLATFORM_ENV_DIR="${BASE_DIR}/platform/env"

	export WORKSPACES_SOURCE_PATH="${BASE_DIR}/workspace/source"

	export WORKSPACES_CACHE_BOUND="false"
	export WORKSPACES_CACHE_PATH="${BASE_DIR}/workspace/cache"

	export RESULTS_APP_IMAGE_DIGEST_PATH="${BASE_DIR}/results/image-digest.txt"
	export RESULTS_APP_IMAGE_URL_PATH="${BASE_DIR}/results/image-digest.txt"

	run mkdir -p -v ${TEKTON_HOME} ${LAYERS_DIR} ${WORKSPACES_SOURCE_PATH}
	assert_success

	run ${prepare_sh}
	assert_success
}

# runs the complete script workflow against a temporary location with mocked directories, asserting
# all script commands will be executed successfully, and also, assert the expected configuration is
# put in place for environment variables and extra bindings.
@test "[prepare.sh] should be able to prepare the workspaces and create environment files" {
	[ -n "${BASE_DIR}" ]

	export TEKTON_HOME="${BASE_DIR}/tekton/home"
	export LAYERS_DIR="${BASE_DIR}/layers"
	export PLATFORM_ENV_DIR="${BASE_DIR}/platform/env"
	export SERVICE_BINDING_ROOT="${BASE_DIR}/bindings"

	export WORKSPACES_SOURCE_PATH="${BASE_DIR}/workspace/source"

	export WORKSPACES_CACHE_BOUND="true"
	export WORKSPACES_CACHE_PATH="${BASE_DIR}/workspace/cache"

	export WORKSPACES_BINDINGS_BOUND="true"
	export WORKSPACES_BINDINGS_PATH="${BASE_DIR}/workspace/bindings"

	export RESULTS_APP_IMAGE_DIGEST_PATH="${BASE_DIR}/results/image-digest.txt"
	export RESULTS_APP_IMAGE_URL_PATH="${BASE_DIR}/results/image-digest.txt"

	run mkdir -p -v ${TEKTON_HOME} \
		${LAYERS_DIR} \
		${SERVICE_BINDING_ROOT} \
		${WORKSPACES_SOURCE_PATH} \
		${WORKSPACES_CACHE_PATH} \
		${WORKSPACES_BINDINGS_PATH}
	assert_success

	touch "${WORKSPACES_BINDINGS_PATH}/cert.pem"
	assert_success

	# running the prepare script informing a enviroment variables
	run ${prepare_sh} "key=value" "k=v" "empty="
	assert_success

	# making sure the variables informed as script argument is creating the expected files
	assert_file_contains "${PLATFORM_ENV_DIR}/key" '^value$'
	assert_file_contains "${PLATFORM_ENV_DIR}/k" '^v$'
	assert_file_empty "${PLATFORM_ENV_DIR}/empty"

	# asserting the extra binding file is copied to the expected location
	assert_file_exists "${WORKSPACES_BINDINGS_PATH}/cert.pem"
}
