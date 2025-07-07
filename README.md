# CrashOverride Helm charts

This repository provides any public facing helm charts for projects managed by [CrashOverride](https://crashoverride.com/).

The charts are hosted using GitHub pages from the branch [`gh-pages`](../../tree/gh-pages)

## Available Charts

| Chart                      | Current Version | Description                             | Documentation      |
|----------------------------|-----------------|-----------------------------------------|--------------------|
| [`ocular`](/charts/ocular) | `v0.2.2`        | [Ocular](crashappsec/ocular) deployment | ~~[Artifact Hub]()~~ |

## Installing Charts

```bash
helm repo add crashoverride https://crashappsec.github.io/helm-charts
# To update use
# helm repo update crashoverride

# Install a chart (for example ocular)
helm install ocular crashoverride/ocular
```

