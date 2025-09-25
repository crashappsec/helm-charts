# Copyright (C) 2025 Crash Override, Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the FSF, either version 3 of the License, or (at your option) any later version.
# See the LICENSE file in the root of this repository for full license text or
# visit: <https://www.gnu.org/licenses/gpl-3.0.html>.

OCULAR_REPOSITORY_ROOT ?= ../ocular

OCULAR_VERSION ?= latest
export OCULAR_VERSION

###############
# Development #
###############
.PHONY: fmt fmt-license

fmt: fmt-license

fmt-license:
	@echo "Formatting license headers ..."
	@license-eye header fix

.PHONY: generate-ocular-helm-chart
generate-ocular-helm-chart:
	@hack/scripts/ocular/generate-helm-chart.sh --repository ${OCULAR_REPOSITORY_ROOT}