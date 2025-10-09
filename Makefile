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
.PHONY: helm-package-%
helm-package-%:
	@helm package charts/$(@:helm-package-%=%) -d out/$(@:helm-package-%=%)

# Can push a helm artfiact to a OCI registry
.PHONY: helm-push-%
helm-push-%: helm-package-%
	@if [ -z '$(CHART_REPOSITORY)' ]; then echo "ERROR: must set CHART_REPOSITORY varibale"; exit 1; fi
	@CHART=$(@:helm-push-%=%); \
		VERSION=$$(helm show chart charts/$$CHART | yq '.version'); \
		FILE=out/$$CHART/$$CHART-$$VERSION.tgz; \
		echo "this target will push the chart '$$FILE' to '$(CHART_REPOSITORY)'"; \
		read -r -p "continue? ( ctrl+c to cancel, or enter to contiue ):" YN
	@CHART=$(@:helm-push-%=%); \
		VERSION=$$(helm show chart charts/$$CHART | yq '.version'); \
		FILE=out/$$CHART/$$CHART-$$VERSION.tgz; \
		helm push $$FILE $(CHART_REPOSITORY)

.PHONY: helm-generate-%
helm-generate-%:
	@hack/scripts/$(@:helm-generate-%=%)/generate-helm-chart.sh --repository ../$(@:helm-generate-%=%)
