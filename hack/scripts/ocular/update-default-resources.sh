#!/bin/bash
# Copyright (C) 2025 Crash Override, Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the FSF, either version 3 of the License, or (at your option) any later version.
# See the LICENSE file in the root of this repository for full license text or
# visit: <https://www.gnu.org/licenses/gpl-3.0.html>.


SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

set -e

release_version="${1:-latest}"

required_commands=(jq unzip yq)
for cmd in "${required_commands[@]}"; do
    if ! command -v "$cmd" > /dev/null; then
	echo "'$cmd' not detected, please ensure it is installed and located in your $$PATH"
    fi
done

if [[ ! "$(yq --help)" =~ "github.com/mikefarah/yq" ]]; then
    echo "wrong version of 'yq' detected, please use https://github.com/mikefarah/yq"
fi
    


download_release() {
    identifier="$1"

    output_folder="$(mktemp -d -t ocular-default-integrations)"
    zip_path="$(mktemp -t ocular-default-integrations-zip)"

    api_url="https://api.github.com/repos/crashappsec/ocular-default-integrations/releases/${identifier}"

    download_url="$(
	curl \
	    -H "Authorization: Bearer $GITHUB_TOKEN" \
	    -H "X-GitHub-Api-Version: 2022-11-28" \
	    -H "Accept: application/vnd.github+json" \
	    -fsSL "${api_url}" \
	    | jq -r '.assets []| select(.name | startswith("ocular-default-integrations-definitions-")) | .url'
		 )"

    # Have to set 'application/octet-stream' in order to get raw asset
    # and not metadata
    curl -fsSL \
	 -H "Authorization: Bearer $GITHUB_TOKEN" \
	 -H "Accept: application/octet-stream" \
	 "$download_url" -o "$zip_path"

    unzip -qq "$zip_path" -d "$output_folder"

    rm -f "$zip_path"

    echo "$output_folder"
}



release_identifier="latest"

shopt -s extglob # we have to enable extglob for the following regex patterns to work
case "$release_version" in
    latest )
	echo;;
    (v+([0-9]).+([0-9]).+([0-9])?(-@(alpha|beta|rc).+([0-9])) )
    release_identifier="tags/$release_version";;
    (+([0-9]).+([0-9]).+([0-9])?(-@(alpha|beta|rc).+([0-9])) )
    release_identifier="tag/v$release_version";;
    *)
	echo "invalid version '$release_version', should be of the form 'vX.X.X' or 'latest'" 1>&2; exit 1;;
esac
							    

definitions=$(download_release "$release_identifier")

echo "{{/*
This file is auto generated
DO NOT EDIT
*/}}
"

for resource_definitions in "$definitions"/*; do
    resource_defaults=""
    resource_type=$(basename "$resource_definitions")
    for def in "$resource_definitions"/*; do
	resource_name=$(basename "$def")
	# resource_definition=$(cat "$def")
	resource_defaults="$resource_defaults
${resource_name%.*}: |
$(cat "$def" | sed 's/^/  /')
"
    done

    echo "{{- define \"${resource_type}.defaults\" -}}"
    echo "$resource_defaults"
    echo -e "{{- end }}\n"
done
    
							    