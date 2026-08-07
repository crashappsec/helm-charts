# Chalk Operator Helm Chart

A Kubernetes operator that enriches pods with cluster and cloud metadata so that
[Chalk](https://crashoverride.com/) (and anything else that reads the environment)
can tell exactly where and how a container is running.

The operator runs as a **mutating admission webhook**. When a pod is created with
the `crashoverride.run/chalk` annotation (set directly on the pod or on its
namespace), the operator enriches every container and init container in the pod
with a set of `CHALK_K8S_*` environment variables and a projected service-account
token used to authenticate to the pod-manifest endpoint. Pods without the
annotation are left untouched.

## Installation

```bash
helm repo add crashoverride https://crashappsec.github.io/helm-charts
helm repo update crashoverride

helm install chalk-operator crashoverride/chalk-operator \
  --namespace chalk-operator-system \
  --create-namespace
```

The image is published to GitHub Container Registry
(`ghcr.io/crashappsec/chalk-operator`) for `linux/amd64`, `linux/arm64`,
`linux/s390x`, and `linux/ppc64le`.

### With cert-manager

```bash
helm install chalk-operator crashoverride/chalk-operator \
  --create-namespace \
  --namespace chalk-operator-system \
  --set certmanager.enable=true
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `chalk.clusterName` | Optional cluster name, recorded alongside the auto-detected one. Empty means rely on detection — see [Cloud-aware metadata](#cloud-aware-metadata) | `""` |
| `podmanifest.enable` | Enable the per-pod manifest endpoint | `true` |
| `podmanifest.containerPort` | Port the manifest service listens on | `9000` |
| `controllerManager.replicas` | Number of controller replicas | `2` |
| `controllerManager.container.image.repository` | Controller image repository | `"controller"` |
| `controllerManager.container.image.tag` | Controller image tag | `"latest"` |
| `controllerManager.container.env` | Environment variables for the controller | `{}` |
| `controllerManager.container.resources.limits.cpu` | CPU limit | `"500m"` |
| `controllerManager.container.resources.limits.memory` | Memory limit | `"128Mi"` |
| `controllerManager.container.resources.requests.cpu` | CPU request | `"10m"` |
| `controllerManager.container.resources.requests.memory` | Memory request | `"64Mi"` |
| `rbac.enable` | Enable RBAC resources | `true` |
| `metrics.enable` | Enable metrics endpoint | `true` |
| `webhook.enable` | Enable admission webhook | `true` |
| `webhook.excludeOperatorNamespace` | Skip pods in the operator's own namespace | `false` |
| `prometheus.enable` | Create a `ServiceMonitor` for metrics scraping | `false` |
| `certmanager.enable` | Use cert-manager for webhook certs (self-signed if `false`) | `false` |
| `networkPolicy.enable` | Enable NetworkPolicies | `false` |

See [`values.yaml`](values.yaml) for the full list.

### Certificate management

- **`certmanager.enable: false`** (default): self-signed certificates are
  generated via Helm hooks.
- **`certmanager.enable: true`**: cert-manager `Certificate` and `Issuer`
  resources are created. If cert-manager CRDs are not present the operator
  falls back to self-signed certificates automatically.

## Usage

Instrument a whole namespace — all new pods in the namespace are enriched:

```bash
kubectl annotate namespace my-app crashoverride.run/chalk=true
```

Or opt in a single workload via its pod template:

```yaml
spec:
  template:
    metadata:
      annotations:
        crashoverride.run/chalk: "true"   # also accepts "enabled"
```

The webhook only fires on pod **creation**. Restart or roll existing pods to
enrich them. A pod-level annotation takes precedence over the namespace
annotation.

### What gets injected

For every annotated pod the operator:

1. Adds the following environment variables to every container and init container:

| Variable | Description |
|----------|-------------|
| `CHALK_K8S_METADATA` | JSON blob of cluster/cloud metadata (provider, cluster name, region, labels, annotations, …) |
| `CHALK_K8S_POD_NAME` | Pod name (Downward API) |
| `CHALK_K8S_POD_NAMESPACE` | Pod namespace (Downward API) |
| `CHALK_K8S_NODE_NAME` | Node the pod is scheduled on (Downward API) |
| `CHALK_K8S_CONTAINER_NAME` | Name of the specific container the variable is added to |
| `CHALK_K8S_PODMANIFEST_URL` | Per-pod URL of the scrubbed pod-manifest endpoint (injected only when `podmanifest.enable=true`) |
| `CHALK_K8S_PODMANIFEST_TOKEN_PATH` | Path to the projected SA token used to authenticate to that endpoint |

2. Mounts a projected service-account token at
   `/var/run/secrets/chalk.crashoverride.run/token` (audience:
   `podmanifest.crashoverride.run`) so the pod can authenticate to the
   pod-manifest endpoint even when `automountServiceAccountToken: false`.

### Cloud-aware metadata

At startup the operator inspects node provider IDs, node labels, and
LoadBalancer service annotations to identify the cloud — AWS (EKS), GCP (GKE),
or Azure (AKS), in that order — and populates `CHALK_K8S_METADATA` with
provider-specific details (region, VPC / project / subscription, endpoint, …).
Unrecognized environments fall back to a generic provider with no `cloud` block.

The cluster name comes from the same sources: the `aws-node` DaemonSet or
`*/cluster-name` node labels on EKS, `cloud.google.com/gke-cluster-name` on GKE,
`kubernetes.azure.com/cluster` on AKS. Where none of those exist the name is
reported as `"unknown"`. `cluster.uid` — the UID of the `kube-system` namespace —
is always present and is the more reliable cluster identifier.

Set `chalk.clusterName` to give the cluster a name you recognize. It is recorded
as `cluster.user_provided_name` alongside whatever was detected — it does not
override the detected name, but it is the only way to identify clusters where
detection reports `"unknown"`. Detection happens once at startup, so restart the
operator if any of these facts change.

## Examples

### Production values file

```yaml
chalk:
  clusterName: "production-cluster"

controllerManager:
  replicas: 2
  container:
    resources:
      limits:
        cpu: 1000m
        memory: 256Mi
      requests:
        cpu: 100m
        memory: 128Mi

prometheus:
  enable: true

certmanager:
  enable: true

networkPolicy:
  enable: true
```

```bash
helm install chalk-operator crashoverride/chalk-operator \
  --namespace chalk-operator-system \
  --create-namespace \
  --values values-production.yaml
```

### Custom image

```bash
helm install chalk-operator crashoverride/chalk-operator \
  --set controllerManager.container.image.repository="my-registry/chalk-operator" \
  --set controllerManager.container.image.tag="v1.0.0" \
  --namespace chalk-operator-system \
  --create-namespace
```

## Upgrading

```bash
helm repo update crashoverride
helm upgrade chalk-operator crashoverride/chalk-operator -n chalk-operator-system
```

## Uninstalling

```bash
helm uninstall chalk-operator -n chalk-operator-system
kubectl delete namespace chalk-operator-system
```

**Note:** CRDs are kept by default (`crd.keep: true`). To remove them:

```bash
kubectl delete crd $(kubectl get crd -o name | grep chalk-operator)
```

## Troubleshooting

### Webhook admission failures

```bash
kubectl get mutatingwebhookconfiguration
kubectl describe mutatingwebhookconfiguration chalk-operator-mutating-webhook-configuration
kubectl logs -n chalk-operator-system deployment/chalk-operator-controller-manager
```

### Certificate issues

```bash
# cert-manager
kubectl get certificates -n chalk-operator-system
kubectl describe certificate chalk-operator-serving-cert -n chalk-operator-system

# self-signed
kubectl logs -n chalk-operator-system deployment/chalk-operator-controller-manager | grep -i cert
```

### Pod not being mutated

```bash
# Verify the webhook is registered
kubectl get mutatingwebhookconfiguration chalk-operator-mutating-webhook-configuration -o yaml

# Check the annotation is present
kubectl get pod <pod-name> -o yaml | grep crashoverride.run/chalk

# Check the operator processed the pod
kubectl logs -n chalk-operator-system deployment/chalk-operator-controller-manager
```

## License

Apache 2.0 License
