# Chalk Operator Helm Chart

A Kubernetes operator that injects cluster metadata into pods marked with the `crashoverride.run/chalk: "true"` annotation.

## Installation

### Prerequisites

- Kubernetes 1.19+
- Helm 3.12+

### Quick Start

```bash
# Generate the chart from operator manifests
make helm-chart

# Install the operator
helm install chalk-operator ./dist/chart \
  --create-namespace \
  --namespace chalk-operator-system
```

### Installation Options

#### Default Installation (Self-Signed Certificates)
```bash
helm install chalk-operator ./dist/chart \
  --create-namespace \
  --namespace chalk-operator-system
```

#### With cert-manager Integration
```bash
# If you have cert-manager installed
helm install chalk-operator ./dist/chart \
  --create-namespace \
  --namespace chalk-operator-system \
  --set certmanager.enable=true
```

#### Custom Configuration
```bash
helm install chalk-operator ./dist/chart \
  --create-namespace \
  --namespace chalk-operator-system \
  --set chalk.clusterName="production" \
  --set controllerManager.replicas=2 \
  --set prometheus.enable=true
```

## Configuration

The following table lists the configurable parameters of the Chalk Operator chart and their default values.

### Core Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `chalk.clusterName` | Cluster name injected into pods | `"my-cluster"` |

### Controller Manager

| Parameter | Description | Default |
|-----------|-------------|---------|
| `controllerManager.replicas` | Number of controller replicas | `1` |
| `controllerManager.container.image.repository` | Controller image repository | `"controller"` |
| `controllerManager.container.image.tag` | Controller image tag | `"latest"` |
| `controllerManager.container.env` | Environment variables | `{}` |
| `controllerManager.container.resources.limits.cpu` | CPU limit | `"500m"` |
| `controllerManager.container.resources.limits.memory` | Memory limit | `"128Mi"` |
| `controllerManager.container.resources.requests.cpu` | CPU request | `"10m"` |
| `controllerManager.container.resources.requests.memory` | Memory request | `"64Mi"` |

### Features

| Parameter | Description | Default |
|-----------|-------------|---------|
| `rbac.enable` | Enable RBAC resources | `true` |
| `crd.enable` | Install CRDs | `true` |
| `crd.keep` | Keep CRDs on uninstall | `true` |
| `metrics.enable` | Enable metrics endpoint | `true` |
| `webhook.enable` | Enable admission webhook | `true` |
| `webhook.excludeOperatorNamespace` | Exclude operator namespace from processing | `false` |
| `prometheus.enable` | Enable Prometheus ServiceMonitor | `false` |
| `certmanager.enable` | Use cert-manager for certificates | `false` |
| `networkPolicy.enable` | Enable NetworkPolicies | `false` |

### Certificate Management

Certificate management is controlled by the `certmanager.enable` setting:

- **`certmanager.enable: true`**: Operator attempts to use cert-manager. If cert-manager CRDs are not available, automatically falls back to self-signed certificates.
- **`certmanager.enable: false`** (default): Operator always uses self-signed certificates.

## Usage

Once installed, the operator will automatically inject metadata into pods with the chalk annotation:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
  annotations:
    crashoverride.run/chalk: "true"
spec:
  containers:
  - name: app
    image: nginx
```

The operator injects these environment variables:
- `CHALK_K8S_METADATA` - JSON object containing all metadata
- `CHALK_K8S_POD_NAME` - Pod name (via Downward API)
- `CHALK_K8S_NODE_NAME` - Node name (via Downward API)

The `CHALK_K8S_METADATA` contains a JSON structure like:
```json
{
  "cluster": {
    "name": "my-cluster",
    "uid": "cluster-uid",
    "endpoint": "https://api.cluster.example.com"
  },
  "pod": {
    "namespace": "default",
    "labels": {"app": "myapp"},
    "annotations": {"key": "value"}
  },
  "cloud": {
    "provider": "aws",
    "region": "us-west-2",
    "vpc_id": "vpc-12345"
  }
}
```

## Examples

### Production Configuration
```yaml
# values-production.yaml
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
helm install chalk-operator ./dist/chart \
  --namespace chalk-operator-system \
  --create-namespace \
  --values values-production.yaml
```

### Development Configuration
```yaml
# values-dev.yaml
chalk:
  clusterName: "dev-cluster"

controllerManager:
  container:
    image:
      tag: "dev"
    env:
      LOG_LEVEL: "debug"

metrics:
  enable: false

certmanager:
  enable: false
```

### Custom Image
```bash
helm install chalk-operator ./dist/chart \
  --set controllerManager.container.image.repository="my-registry/chalk-operator" \
  --set controllerManager.container.image.tag="v1.0.0" \
  --namespace chalk-operator-system \
  --create-namespace
```

## Upgrading

```bash
# Update chart
make helm-chart

# Upgrade release
helm upgrade chalk-operator ./dist/chart -n chalk-operator-system
```

## Uninstalling

```bash
# Remove the release
helm uninstall chalk-operator -n chalk-operator-system

# Optionally remove the namespace
kubectl delete namespace chalk-operator-system
```

**Note:** CRDs are kept by default (`crd.keep: true`). To remove them:
```bash
kubectl delete crd $(kubectl get crd -o name | grep chalk-operator)
```

## Troubleshooting

### Common Issues

#### Webhook Admission Failures
```bash
# Check webhook configuration
kubectl get mutatingwebhookconfiguration
kubectl describe mutatingwebhookconfiguration chalk-operator-mutating-webhook-configuration

# Check operator logs
kubectl logs -n chalk-operator-system deployment/chalk-operator-controller-manager
```

#### Certificate Issues
```bash
# For cert-manager issues
kubectl get certificates -n chalk-operator-system
kubectl describe certificate chalk-operator-serving-cert -n chalk-operator-system

# For self-signed certificate issues
kubectl logs -n chalk-operator-system deployment/chalk-operator-controller-manager | grep -i cert
```

#### Pod Not Being Modified
```bash
# Verify webhook is registered
kubectl get mutatingwebhookconfiguration chalk-operator-mutating-webhook-configuration -o yaml

# Check if pod has the correct annotation
kubectl get pod <pod-name> -o yaml | grep crashoverride.run/chalk

# Test with example pod
kubectl apply -f examples/test-pod.yaml
kubectl get pod test-chalk-pod -o jsonpath='{.spec.containers[0].env}'
```

### Debug Mode
```bash
# Enable debug logging
helm upgrade chalk-operator ./dist/chart \
  --set controllerManager.container.env.LOG_LEVEL="debug" \
  -n chalk-operator-system
```

## Contributing

For chart development:

1. Make changes to the operator manifests in `config/`
2. Run `make helm-chart` to regenerate the chart
3. Test with `helm template` and `helm install --dry-run`
4. Update this README if needed

## License

Apache 2.0 License
