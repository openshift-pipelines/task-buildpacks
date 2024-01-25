SHELL := /usr/bin/env bash
BIN = $(CURDIR)/.bin

OSP_VERSION ?= latest

# using the chart name and version from chart's metadata
CHART_NAME ?= $(shell awk '/^name:/ { print $$2 }' Chart.yaml)
CHART_VESION ?= $(shell awk '/^version:/ { print $$2 }' Chart.yaml)

# bats entry point and default flags
BATS_CORE = ./test/.bats/bats-core/bin/bats
BATS_FLAGS ?= --print-output-on-failure --show-output-of-passing-tests --verbose-run

# path to the bats test files, overwite the variables below to tweak the test scope
INTEGRATION_TESTS ?= ./test/integration/*.bats
E2E_TESTS ?= ./test/e2e/*.bats

# external task dependency to run the end-to-end tests pipeline
TASK_GIT ?= https://github.com/openshift-pipelines/task-git/releases/download/0.0.1/task-git-0.0.1.yaml

# buildpacks pipelinerun parameters, the git repository url and the container image fully qualified
# picked up by the "test-e2e" target
E2E_PARAM_URL ?= https://github.com/paketo-buildpacks/samples.git
E2E_PARAM_SUBDIRECTORY ?= nodejs/npm

# container registry URL, usually hostname and port
REGISTRY_URL ?= registry.registry.svc.cluster.local:32222
# containre registry namespace, as in the section of the registry allowed to push images
REGISTRY_NAMESPACE ?= task-buildpacks
# base part of a fully qualified container image name
IMAGE_BASE ?= $(REGISTRY_URL)/$(REGISTRY_NAMESPACE)

# simple image name, followed by tag
E2E_IMAGE_TAG ?= samples-nodejs:latest
# task parameter with the fully qualified image name, to be built with buildpacks
E2E_PARAM_IMAGE ?= $(IMAGE_BASE)/${E2E_IMAGE_TAG}

# workspace "source" pvc resource and name
E2E_PVC ?= test/e2e/resources/01-pvc.yaml
E2E_PVC_NAME ?= task-buildpacks

# generic arguments employed on most of the targets
ARGS ?=

# making sure the variables declared in the Makefile are exported to the excutables/scripts invoked
# on all targets
.EXPORT_ALL_VARIABLES:

# uses helm to render the resource templates to the stdout
define render-template
	@helm template $(ARGS) $(CHART_NAME) .
endef

$(BIN):
	@mkdir -p $@

CATALOGCD = $(or ${CATALOGCD_BIN},${CATALOGCD_BIN},$(BIN)/catalog-cd)
$(BIN)/catalog-cd: $(BIN)
	curl -fsL https://github.com/openshift-pipelines/catalog-cd/releases/download/v0.1.0/catalog-cd_0.1.0_linux_x86_64.tar.gz | tar xzf - -C $(BIN) catalog-cd

# pepare a release
.PHONY: prepare-release
prepare-release:
	mkdir -p $(RELEASE_DIR) || true
	hack/release.sh $(RELEASE_DIR)

.PHONY: release
release: prepare-release
	pushd ${RELEASE_DIR} && \
		$(CATALOGCD) release \
			--output release \
			--version $(CHART_VERSION) \
			tasks/* \
		; \
	popd

# tags the repository with the RELEASE_VERSION and pushes to "origin"
git-tag-release-version:
	if ! git rev-list "${RELEASE_VERSION}".. >/dev/null; then \
		git tag "$(RELEASE_VERSION)" && \
			git push origin --tags; \
	fi

# github-release
.PHONY: github-release
github-release: git-tag-release-version release
	gh release create $(RELEASE_VERSION) --generate-notes && \
	gh release upload $(RELEASE_VERSION) $(RELEASE_DIR)/release/catalog.yaml && \
	gh release upload $(RELEASE_VERSION) $(RELEASE_DIR)/release/resources.tar.gz


# renders the task resource file printing it out on the standard output
helm-template:
	$(call render-template)

default: helm-template

# renders and installs the resources (task)
install:
	$(call render-template) |kubectl $(ARGS) apply -f -

# installs "git" task directly from the informed location, the task is required to run the test-e2e
# target, it will hold the "source" workspace data
task-git:
	kubectl apply -f ${TASK_GIT}

# packages the helm-chart as a single tarball, using it's name and version to compose the file
helm-package: clean
	helm package $(ARGS) .
	tar -ztvpf $(CHART_NAME)-$(CHART_VESION).tgz

# removes the package helm chart, and also the chart-releaser temporary directories
clean:
	rm -rf $(CHART_NAME)-*.tgz > /dev/null 2>&1 || true

# applies the pvc resource file, if the file exists
.PHONY: workspace-source-pvc
workspace-source-pvc:
ifneq ("$(wildcard $(E2E_PVC))","")
	kubectl apply -f $(E2E_PVC)
endif

# run the integration tests, does not require a kubernetes instance
test-integration:
	$(BATS_CORE) $(BATS_FLAGS) $(ARGS) $(INTEGRATION_TESTS)

# run end-to-end tests against the current kuberentes context, it will required a cluster with tekton
# pipelines and other requirements installed, before start testing the target invokes the
# installation of the current project's task (using helm).
test-e2e: task-git workspace-source-pvc install
	$(BATS_CORE) $(BATS_FLAGS) $(ARGS) $(E2E_TESTS)

# Run all the end-to-end tests against the current openshift context.
# It is used mainly by the CI and ideally shouldn't differ that much from test-e2e
.PHONY: prepare-e2e-openshift
prepare-e2e-openshift:
	./hack/install-osp.sh $(OSP_VERSION)
.PHONY: test-e2e-openshift
test-e2e-openshift: prepare-e2e-openshift
test-e2e-openshift: REGISTRY_URL = image-registry.openshift-image-registry.svc.cluster.local:5000
test-e2e-openshift: REGISTRY_NAMESPACE = $(shell oc project -q)
test-e2e-openshift: test-e2e

# act runs the github actions workflows, so by default only running the test workflow (integration
# and end-to-end) to avoid running the release workflow accidently
act: ARGS = --rm --workflows=./.github/workflows/test.yaml
act:
	act $(ARGS)
