# Copyright (C) 2025 Crash Override, Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the FSF, either version 3 of the License, or (at your option) any later version.
# See the LICENSE file in the root of this repository for full license text or
# visit: <https://www.gnu.org/licenses/gpl-3.0.html>.

###############
# Development #
###############
.PHONY: clean fmt fmt-license

clean:
	@rm -rf "$$TMPDIR"/ocular-default-integrations-*

fmt: fmt-license

fmt-license:
	@echo "Formatting license headers ..."
	@license-eye header fix



.PHONY: ocular-update-defaults

OCULAR_DEFAULTS_VERSION ?= latest
ocular-update-defaults:
	@hack/scripts/ocular/update-default-resources.sh ${OCULAR_DEFAULTS_VERSION} > ./charts/ocular/templates/_storage_defaults.tpl