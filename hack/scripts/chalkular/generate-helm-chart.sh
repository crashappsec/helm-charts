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

CHALKULAR_REPO_ROOT=$(readlink -f "$REPO_ROOT/../chalkular")

while [[ $# -gt 0 ]]; do
  case $1 in
    -r|--repository)
      CHALKULAR_REPO_ROOT="$(readlink -f "$2")"
      shift
      shift
      ;;
    *)
      shift
      ;;
  esac
done


if [ ! -d "$CHALKULAR_REPO_ROOT" ]; then
    echo "'$CHALKULAR_REPO_ROOT' is not a directory"
fi

go_module=$(cd "$CHALKULAR_REPO_ROOT" &>/dev/null && go list)

if [ ! "$go_module" = "github.com/crashappsec/chalkular" ]; then
    echo "ERROR: path '$go_module' is not the chalkular repository root" >&2
    exit 1
fi

# first clean the existing chart from the ocular repository
CHALKULAR_ENV_FILE='' make -C "$CHALKULAR_REPO_ROOT" clean-helm

# Then we copy in the current chart from this repository, then run
# the 'build-helm' target.
# This is done because the kubebuilder command has logic of which existing
# files to update and which to leave alone, and the helm-chart plugin
# will read/write to the folder 'dist/chart' within the repository
cp -r "$REPO_ROOT/charts/chalkular/" "$CHALKULAR_REPO_ROOT/dist/chart/"

CHALKULAR_ENV_FILE='' CHALKULAR_VERSION=$(git -C "$CHALKULAR_REPO_ROOT" describe --tags --dirty=-dev) make -C "$CHALKULAR_REPO_ROOT" build-helm

# Once the files are updated, copy them back
rm -rf "$REPO_ROOT/charts/chalkular"
cp -r "$CHALKULAR_REPO_ROOT/dist/chart/" "$REPO_ROOT/charts/chalkular"

