# Q2 (7%) — HTTPRoute Traffic Splitting

**Time budget: ~12 min**

## Context

Namespace `gw-demo` contains `web-gateway` (from Q1) and Deployments `app-v1` / `app-v2` fronted by ClusterIP Services `app-v1-svc` / `app-v2-svc` on port 80.

## Task

Create an `HTTPRoute` named `app-route` attached to `web-gateway` such that:

- Requests to host `app.local` with path prefix `/` are split **80/20** between `app-v1-svc` and `app-v2-svc`.
- Requests with header `x-canary: true` go **100% to `app-v2-svc`** regardless of weight.

```bash
kubectl apply -f - <<'EOF'
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: app-route
  namespace: gw-demo
spec:
  parentRefs:
  - name: web-gateway
  hostnames:
  - "app.local"
  rules:
  # Rule 1: canary header — 100% to v2
  - matches:
    - headers:
      - name: x-canary
        value: "true"
    backendRefs:
    - name: app-v2-svc
      port: 80
      weight: 100
  # Rule 2: default weighted split 80/20
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: app-v1-svc
      port: 80
      weight: 80
    - name: app-v2-svc
      port: 80
      weight: 20
EOF
```{{exec}}

## Verify

Check the route exists and run a quick curl from a debug pod:

```bash
kubectl get httproute app-route -n gw-demo -o yaml
```{{exec}}

```bash
GW_IP=$(kubectl get gateway web-gateway -n gw-demo \
  -o jsonpath='{.status.addresses[0].value}')
kubectl run debug --image=curlimages/curl:8.6.0 --restart=Never --rm -i -- \
  curl -s -H "Host: app.local" "http://${GW_IP}/"
```{{exec}}

```bash
GW_IP=$(kubectl get gateway web-gateway -n gw-demo \
  -o jsonpath='{.status.addresses[0].value}')
kubectl run debug-canary --image=curlimages/curl:8.6.0 --restart=Never --rm -i -- \
  curl -s -H "Host: app.local" -H "x-canary: true" "http://${GW_IP}/"
```{{exec}}

<details><summary>Solution</summary>

```bash
kubectl apply -f - <<'EOF'
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: app-route
  namespace: gw-demo
spec:
  parentRefs:
  - name: web-gateway
  hostnames:
  - "app.local"
  rules:
  - matches:
    - headers:
      - name: x-canary
        value: "true"
    backendRefs:
    - name: app-v2-svc
      port: 80
      weight: 100
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: app-v1-svc
      port: 80
      weight: 80
    - name: app-v2-svc
      port: 80
      weight: 20
EOF
```{{exec}}

</details>
