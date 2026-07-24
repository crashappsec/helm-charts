#!/usr/bin/env bash
# Copyright (C) 2025 Crash Override, Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the FSF, either version 3 of the License, or (at your option) any later version.
# See the LICENSE file in the root of this repository for full license text or
# visit: <https://www.gnu.org/licenses/gpl-3.0.html>.


SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
REPO_ROOT=$(readlink -f "$SCRIPT_DIR/../../../")

set -e

CHALK_OPERATOR_REPO_ROOT=$(readlink -f "$REPO_ROOT/../chalk-operator")

CHALK_OPERATOR_HELM_VERSION=0.0.0-dev

while [[ $# -gt 0 ]]; do
    case $1 in
	-r|--repository)
	    CHALK_OPERATOR_REPO_ROOT="$(readlink -f "$2")"
	    shift
	    shift
	    ;;
	-v|--version)
	    CHALK_OPERATOR_HELM_VERSION="$2"
	    shift
	    shift
	    ;;
	*)
	    shift
	    ;;
    esac
done


if [ ! -d "$CHALK_OPERATOR_REPO_ROOT" ]; then
    echo "'$CHALK_OPERATOR_REPO_ROOT' is not a directory" >&2
    exit 1
fi

go_module=$(cd "$CHALK_OPERATOR_REPO_ROOT" &>/dev/null && go list -m)

if [ ! "$go_module" = "github.com/crashappsec/chalk-operator" ]; then
    echo "ERROR: path '$go_module' is not the chalk-operator repository root" >&2
    exit 1
fi

# strip a leading 'v' from the version if present (chart version is bare semver)
VERSION="${CHALK_OPERATOR_HELM_VERSION#v}"

# chalk-operator commits its rendered chart under dist/chart, so unlike the
# other charts we vendor the committed chart directly rather than regenerating
# it via a source-repo make target.
CHART_SRC="$CHALK_OPERATOR_REPO_ROOT/dist/chart"
if [ ! -d "$CHART_SRC" ]; then
    echo "ERROR: '$CHART_SRC' not found; run 'make helm-chart' in chalk-operator first" >&2
    exit 1
fi

# copy the chart in
rm -rf "$REPO_ROOT/charts/chalk-operator"
cp -r "$CHART_SRC/" "$REPO_ROOT/charts/chalk-operator"

YQ="${YQ:-yq}"

# stamp the chart version + appVersion
"$YQ" -i ".version = \"$VERSION\" | .appVersion = \"$VERSION\"" \
    "$REPO_ROOT/charts/chalk-operator/Chart.yaml"

# point the chart at the public image. NOTE: the chalk-operator manager
# template renders the tag verbatim (no `tpl`), so a concrete tag must be
# stamped here rather than a templated `v{{ .Chart.AppVersion }}` string.
"$YQ" -i "
    .controllerManager.container.image.repository = \"ghcr.io/crashappsec/chalk-operator\" |
    .controllerManager.container.image.tag = \"v$VERSION\"
" "$REPO_ROOT/charts/chalk-operator/values.yaml"

# ArtifactHub metadata (kept here so it survives a re-vendor of the chart)
"$YQ" -i "
    .annotations.\"artifacthub.io/category\" = \"security\" |
    .annotations.\"artifacthub.io/license\" = \"GPL-3.0\"
" "$REPO_ROOT/charts/chalk-operator/Chart.yaml"
