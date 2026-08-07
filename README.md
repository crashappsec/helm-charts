# CrashOverride Helm charts

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/crashoverride-helm-charts)](https://artifacthub.io/packages/search?repo=crashoverride-helm-charts)

This repository provides any public facing helm charts for projects managed by [CrashOverride](https://crashoverride.com/).

The charts are hosted using GitHub pages from the branch [`gh-pages`](https://github.com/crashappsec/helm-charts/tree/gh-pages)

## Available Charts

| Chart                                                                                                                    | Current Version | Repo                                                                                                  | Documentation                                                                                              |
| ------------------------------------------------------------------------------------------------------------------------ | --------------- | ----------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| [`ocular`](https://github.com/crashappsec/helm-charts/tree/main/charts/ocular)                                           | `v0.5.0`        | [crashappsec/ocular](https://github.com/crashappsec/ocular)                                           | [Artifact Hub](https://artifacthub.io/packages/helm/crashoverride-helm-charts/ocular)                      |
| [`ocular-default-integrations`](https://github.com/crashappsec/helm-charts/tree/main/charts/ocular-default-integrations) | `v0.2.0`        | [crashappsec/ocular-default-integrations](https://github.com/crashappsec/ocular-default-integrations) | [Artifact Hub](https://artifacthub.io/packages/helm/crashoverride-helm-charts/ocular-default-integrations) |
| [`chalkular`](https://github.com/crashappsec/helm-charts/tree/main/charts/chalkular)                                     | `v0.0.6`        | [crashappsec/chalkular](https://github.com/crashappsec/chalkular)                                     | [Artifact Hub](https://artifacthub.io/packages/helm/crashoverride-helm-charts/chalkular)                   |
| [`chalk-operator`](https://github.com/crashappsec/helm-charts/tree/main/charts/chalk-operator)                           | `v0.1.0`        | [Charts README](https://github.com/crashappsec/helm-charts/blob/main/charts/chalk-operator/README.md) | [Artifact Hub](https://artifacthub.io/packages/helm/crashoverride-helm-charts/chalk-operator)              |

## Installing Charts

```bash
helm repo add crashoverride https://crashappsec.github.io/helm-charts
# To update use
# helm repo update crashoverride

# Install a chart (for example ocular)
helm install ocular crashoverride/ocular \
	--namespace ocular-system \
	--create-namespace
```
