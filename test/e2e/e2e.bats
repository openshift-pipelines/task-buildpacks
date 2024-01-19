#!/usr/bin/env bats

source ./test/helper/helper.sh

# e2e tests paramters for the test pipeline
declare E2E_PARAM_URL="${E2E_PARAM_URL:-}"
declare E2E_PARAM_SUBDIRECTORY="${E2E_PARAM_SUBDIRECTORY:-}"
declare E2E_PARAM_IMAGE="${E2E_PARAM_IMAGE:-}"
declare E2E_PVC_NAME="${E2E_PVC_NAME:-}"

# spinning up a PipeineRun using the internal Container-Registry to store the final image, when the
# process is completed the resource is inspected to assert wether sucessful
@test "[e2e] pipeline-run using git and buildpacks tasks" {
	# asserting all required configuration is informed
	[ -n "${E2E_PARAM_URL}" ]
	[ -n "${E2E_PARAM_IMAGE}" ]
	[ -n "${E2E_PARAM_SUBDIRECTORY}" ]
	[ -n "${E2E_PVC_NAME}" ]

	# cleaning up all the existing resources before starting a new pipelinerun, the test assertion
	# will describe the objects on the current namespace
	run kubectl delete pipelinerun --all
	assert_success

	#
	# E2E PipelineRun
	#

	run tkn pipeline start task-buildpacks \
		--param="URL=${E2E_PARAM_URL}" \
		--param="SUBDIRECTORY=${E2E_PARAM_SUBDIRECTORY}" \
		--param="IMAGE=${E2E_PARAM_IMAGE}" \
		--param="VERBOSE=true" \
		--workspace="name=source,claimName=${E2E_PVC_NAME},subPath=source" \
		--workspace="name=cache,claimName=${E2E_PVC_NAME},subPath=cache" \
		--workspace="name=bindings,emptyDir=" \
		--filename=test/e2e/resources/10-pipeline.yaml \
		--showlog
	assert_success

	# waiting a few seconds before asserting results
	sleep 30

	# asserting the task status, it must have all steps running sucessfully
	assert_tekton_resource "pipelinerun" --partial '(Failed: 0, Cancelled 0), Skipped: 0'
	# asserting the task results using a regexp to match the expected key-value entries
	assert_tekton_resource "taskrun" --regexp $'IMAGE_DIGEST=\S+.\nIMAGE_URL=\S+*'
}
