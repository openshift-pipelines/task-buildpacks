#!/usr/bin/env bats

source ./test/helper/helper.sh

# e2e tests paramters for the test pipeline
readonly E2E_PARAM_URL="${E2E_PARAM_URL:-}"
readonly E2E_PARAM_SUBDIRECTORY="${E2E_PARAM_SUBDIRECTORY:-}"
readonly E2E_PARAM_APP_IMAGE="${E2E_PARAM_APP_IMAGE:-}"
readonly E2E_PVC_NAME="${E2E_PVC_NAME:-}"

# spinning up a PipeineRun using the internal Container-Registry to store the final image, when the
# process is completed the resource is inspected to assert wether sucessful
@test "[e2e] pipeline-run using git and buildpacks tasks" {
	# asserting all required configuration is informed
	[ -n "${E2E_PARAM_URL}" ]
	[ -n "${E2E_PARAM_APP_IMAGE}" ]
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
		--param="APP_IMAGE=${E2E_PARAM_APP_IMAGE}" \
		--param="VERBOSE=true" \
		--workspace="name=source,claimName=${E2E_PVC_NAME},subPath=source" \
		--workspace="name=cache,claimName=${E2E_PVC_NAME},subPath=cache" \
		--workspace="name=bindings,emptyDir=" \
		--filename=test/e2e/resources/10-pipeline.yaml \
		--showlog >&3
	assert_success

	# waiting a few seconds before asserting results
	sleep 15

	#
	# Asserting Status
	#

	readonly tmpl_file="${BASE_DIR}/go-template.tpl"

	cat >${tmpl_file} <<EOS
{{- range .status.conditions -}}
	{{- if and (eq .type "Succeeded") (eq .status "True") }}
		{{ .message }}
	{{- end }}
{{- end -}}
EOS

	# using template to select the requered information and asserting all tasks have been executed
	# without failed or skipped steps
	run tkn pipelinerun describe --output=go-template-file --template=${tmpl_file}
	assert_success
	assert_output --partial '(Failed: 0, Cancelled 0), Skipped: 0'

	#
	# Asserting Results
	#

	cat >${tmpl_file} <<EOS
{{- range .status.taskRuns -}}
  {{- range .status.taskResults -}}
    {{ printf "%s=%s\n" .name .value }}
  {{- end -}}
{{- end -}}
EOS

	# using a template to render the result attributes on a multi-line key-value pair output, the
	# assertion is based on finding the expected results filled up
	run tkn pipelinerun describe --output=go-template-file --template=${tmpl_file}
	assert_success
	assert_output --regexp $'^APP_IMAGE_DIGEST=\S+\nAPP_IMAGE_URL=\S+.*'
}
