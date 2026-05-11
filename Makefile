# Copyright (C) 2025 Crash Override, Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the FSF, either version 3 of the License, or (at your option) any later version.
# See the LICENSE file in the root of this repository for full license text or
# visit: <https://www.gnu.org/licenses/gpl-3.0.html>.

OCULAR_REPOSITORY_ROOT ?= ../ocular

OCULAR_DI_REPOSITORY_ROOT ?= ../ocular-default-integrations

CHALKULAR_REPOSITORY_ROOT ?= ../chalkular

ENV_FILE ?= .env

# Only if .env file is present
ifneq (,$(wildcard ${ENV_FILE}))
	include ${ENV_FILE}
endif


###############
# Development #
###############

.PHONY: lint
lint: license-eye
	@"$(LICENSE_EYE)" header check

.PHONY: lint-fix
lint-fix: license-eye
	@echo "Formatting license headers ..."
	@"$(LICENSE_EYE)" header fix


GHASOURCEDIR := ./.github/workflows
GHASOURCES := $(shell find $(GHASOURCEDIR) -name '*.yaml')
.PHONY: gha-upgrade
gha-upgrade: ratchet ## upgrades all pinned github actions used in any workflows
	@"$(RATCHET)" upgrade $(GHASOURCES)


# Package a helm chart as a .tar.gz
helm-package-chart-%:
	@helm package charts/$* -d out/$*

.PHONY: helm-package-ocular
helm-package-ocular:
	@$(MAKE) helm-package-chart-ocular

.PHONY: helm-package-ocular-default-integrations
helm-package-ocular-default-integrations:
	@$(MAKE) helm-package-chart-ocular-default-integrations

.PHONY: helm-package-chalkular
helm-package-chalkular:
	@$(MAKE) helm-package-chart-chalkular


# Can push a helm artfiact to a OCI registry
helm-push-chart-%: helm-package-chart-%
	@if [ -z '$(CHART_REPOSITORY)' ]; then echo "ERROR: must set CHART_REPOSITORY varibale"; exit 1; fi
	@CHART=$(@:helm-push-chart-%=%); \
		VERSION=$$(helm show chart charts/$$CHART | yq '.version'); \
		FILE=out/$$CHART/$$CHART-$$VERSION.tgz; \
		echo "this target will push the chart '$$FILE' to '$(CHART_REPOSITORY)'"; \
		read -r -p "continue? ( ctrl+c to cancel, or enter to contiue ):" YN
	@CHART=$(@:helm-push-chart-%=%); \
		VERSION=$$(helm show chart charts/$$CHART | yq '.version'); \
		FILE=out/$$CHART/$$CHART-$$VERSION.tgz; \
		helm push $$FILE $(CHART_REPOSITORY)

.PHONY: helm-push-ocular
helm-push-ocular:
	@$(MAKE) helm-push-chart-ocular

.PHONY: helm-push-ocular-default-integrations
helm-push-ocular-default-integrations:
	@$(MAKE) helm-push-chart-ocular-default-integrations

.PHONY: helm-push-chalkular
helm-push-chalkular:
	@$(MAKE) helm-push-chart-chalkular

helm-generate-chart-%: yq
	@hack/scripts/$*/generate-helm-chart.sh \
		--repository ../$* \
		--version $(shell "$(YQ)" '.version' charts/$*/Chart.yaml)

.PHONY: helm-generate-ocular
helm-generate-ocular:
	@$(MAKE) helm-generate-chart-ocular

.PHONY: helm-generate-ocular-default-integrations
helm-generate-ocular-default-integrations:
	@$(MAKE) helm-generate-chart-ocular-default-integrations


.PHONY: helm-generate-chalkular
helm-generate-chalkular:
	@$(MAKE) helm-generate-chart-chalkular


## Location to install dependencies to
LOCALBIN ?= $(shell pwd)/bin
$(LOCALBIN):
	mkdir -p "$(LOCALBIN)"

## Tool Binaries
YQ ?= $(LOCALBIN)/yq
LICENSE_EYE ?= $(LOCALBIN)/license-eye
RATCHET ?= $(LOCALBIN)/ratchet

## Tool Versions
YQ_VERSION ?= v4.53.2
LICENSE_EYE_VERSION ?= v0.8.0
RATCHET_VERSION ?= v0.11.4



yq: $(YQ) ## Download yq locally if necessary.
$(YQ): $(LOCALBIN)
	$(call go-install-tool,$(YQ),github.com/mikefarah/yq/v4,$(YQ_VERSION))

license-eye: $(LICENSE_EYE) ## Download skywalking-eyes locally if necessary.
$(LICENSE_EYE): $(LOCALBIN)
	$(call go-install-tool,$(LICENSE_EYE),github.com/apache/skywalking-eyes/cmd/license-eye,$(LICENSE_EYE_VERSION))

ratchet: $(RATCHET) ## Download ratchet locally if necessary.
$(RATCHET): $(LOCALBIN)
	$(call go-install-tool,$(RATCHET),github.com/sethvargo/ratchet,$(RATCHET_VERSION))


# go-install-tool will 'go install' any package with custom target and name of binary, if it doesn't exist
# $1 - target path with name of binary
# $2 - package url which can be installed
# $3 - specific version of package
define go-install-tool
@[ -f "$(1)-$(3)" ] && [ "$$(readlink -- "$(1)" 2>/dev/null)" = "$(1)-$(3)" ] || { \
set -e; \
package=$(2)@$(3) ;\
echo "Downloading $${package}" ;\
rm -f $(1) ;\
GOBIN=$(LOCALBIN) go install $${package} ;\
mv $(1) $(1)-$(3) ;\
} ;\
ln -sf $$(realpath $(1)-$(3)) $(1)
endef

