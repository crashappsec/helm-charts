# Copyright (C) 2025 Crash Override, Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the FSF, either version 3 of the License, or (at your option) any later version.
# See the LICENSE file in the root of this repository for full license text or
# visit: <https://www.gnu.org/licenses/gpl-3.0.html>.

OCULAR_REPOSITORY_ROOT ?= ../ocular

OCULAR_DI_REPOSITORY_ROOT ?= ../ocular-default-integrations

ENV_FILE ?= .env

# Only if .env file is present
ifneq (,$(wildcard ${ENV_FILE}))
	include ${ENV_FILE}
endif

define NEWLINE

endef


###############
# Development #
###############

.PHONY: lint-fix
lint-fix:
	@echo "Formatting license headers ..."
	@license-eye header fix

# Package a helm chart as a .tar.gz
helm-package-chart-%:
	@helm package charts/$(@:helm-package-chart-%=%) -d out/$(@:helm-package-chart-%=%)

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


helm-generate-chart-%:
	@hack/scripts/$(@:helm-generate-chart-%=%)/generate-helm-chart.sh --repository ../$(@:helm-generate-chart-%=%)

.PHONY: helm-generate-ocular
helm-generate-ocular:
	@$(MAKE) helm-generate-chart-ocular

.PHONY: helm-generate-ocular-default-integrations
helm-generate-ocular-default-integrations:
	@$(MAKE) helm-generate-chart-ocular-default-integrations


.PHONY: helm-generate-chalkular
helm-generate-chalkular:
	@$(MAKE) helm-generate-chart-chalkular
