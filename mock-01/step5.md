# Q5 (8%) — HPA on Custom Metrics

**Time budget: ~15 min**

## Context

Namespace `metrics-demo` contains a Deployment `orders-api` that exposes the Prometheus metric `orders_in_flight` on `/metrics` port `8080`.

## Task

### 1 · Add the Prometheus Helm repo and install Prometheus

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```{{exec}}

```bash
helm install prometheus prometheus-community/prometheus \
  --namespace metrics-demo \
  --set server.persistentVolume.enabled=false \
  --set alertmanager.enabled=false \
  --wait --timeout 3m
```{{exec}}

### 2 · Install prometheus-adapter

Create a custom rules ConfigMap so the adapter exposes `orders_in_flight` as a Pods metric:

```bash
helm install prometheus-adapter prometheus-community/prometheus-adapter \
  --namespace metrics-demo \
  --set prometheus.url=http://prometheus-server.metrics-demo.svc \
  --set prometheus.port=80 \
  --set rules.custom[0].seriesQuery='orders_in_flight{namespace!="",pod!=""}' \
  --set rules.custom[0].resources.overrides.namespace.resource=namespace \
  --set rules.custom[0].resources.overrides.pod.resource=pod \
  --set rules.custom[0].name.matches='^(.*)$' \
  --set rules.custom[0].name.as='${1}' \
  --set rules.custom[0].metricsQuery='avg(<<.Series>>{<<.LabelMatchers>>})' \
  --wait --timeout 3m
```{{exec}}

### 3 · Verify the custom metrics API

Wait ~60 s for the adapter to scrape, then:

```bash
kubectl get --raw \
  "/apis/custom.metrics.k8s.io/v1beta1/namespaces/metrics-demo/pods/*/orders_in_flight" \
  | python3 -m json.tool
```{{exec}}

### 4 · Create the HPA

```bash
kubectl apply -f - <<'EOF'
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: orders-hpa
  namespace: metrics-demo
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: orders-api
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Pods
    pods:
      metric:
        name: orders_in_flight
      target:
        type: AverageValue
        averageValue: "30"
EOF
```{{exec}}

### 5 · Check HPA status

```bash
kubectl get hpa orders-hpa -n metrics-demo
kubectl describe hpa orders-hpa -n metrics-demo
```{{exec}}

<details><summary>Solution</summary>

Key points:
- `prometheus-adapter` must be configured with a `rules.custom` entry that maps the Prometheus series `orders_in_flight` to the `custom.metrics.k8s.io` API as a Pods-scoped metric.
- The HPA uses `type: Pods` with `metric.name: orders_in_flight` and `target.averageValue: "30"`.
- `minReplicas: 2`, `maxReplicas: 10`.

</details>
