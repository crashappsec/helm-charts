{{ /*
Copyright (C) 2025 Crash Override, Inc.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the FSF, either version 3 of the License, or (at your option) any later version.
See the LICENSE file in the root of this repository for full license text or
visit: <https://www.gnu.org/licenses/gpl-3.0.html>.
*/}}


{{/* Expand the name of the chart. */}}
{{- define "ocular.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "ocular.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "ocular.serviceaccount.namespace" -}}
{{- if .Values.api.serviceAccount.namespace }}
{{- .Values.serviceAccount.namespace | quote }}
{{- else }}
{{- .Release.Namespace | quote }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "ocular.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "ocular.labels" -}}
helm.sh/chart: {{ include "ocular.chart" . }}
{{ include "ocular.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.global.labels }}
{{- with .Values.global.labels }}
{{ toYaml . }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ocular.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ocular.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{- define "images.api-server" }}
{{- $registry := .Values.images.registry | default "ghcr.io" -}}
{{- $repo := .Values.images.repositories.apiServer| default "crashappsec/ocular-api-server" -}}
{{- $tag := .Values.images.tagOverride | default .Chart.AppVersion -}}
{{- printf "%s/%s:%s" $registry $repo $tag -}}
{{- end }}

{{- define "images.extractor" }}
{{- $registry := .Values.images.registry | default "ghcr.io" -}}
{{- $repo := .Values.images.repositories.extractor -}}
{{- $tag := .Values.images.tagOverride | default .Chart.AppVersion -}}
{{- printf "%s/%s:%s" $registry $repo $tag -}}
{{- end }}

