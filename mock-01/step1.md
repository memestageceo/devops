# Q1 (8%) — Gateway API: Install & Basic Routing

**Time budget: ~15 min**

## Context

No Gateway API CRDs are installed on the cluster yet.

## Task

### 1 · Install Gateway API standard channel CRDs (v1.2.0+)

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml
```{{exec}}

Confirm the CRDs landed:

```bash
kubectl get crd gateways.gateway.networking.k8s.io httproutes.gateway.networking.k8s.io
```{{exec}}

### 2 · Install NGINX Gateway Fabric into namespace `nginx-gateway`

```bash
kubectl create namespace nginx-gateway --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f https://raw.githubusercontent.com/nginxinc/nginx-gateway-fabric/v1.4.0/deploy/crds.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/nginx-gateway-fabric/v1.4.0/deploy/default/deploy.yaml
kubectl rollout status deployment nginx-gateway -n nginx-gateway --timeout=120s
```{{exec}}

### 3 · Create the GatewayClass

```bash
kubectl apply -f - <<'EOF'
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: nginx
spec:
  controllerName: gateway.nginx.org/nginx-gateway-controller
EOF
```{{exec}}

### 4 · Create the Gateway in namespace `gw-demo`

```bash
kubectl apply -f - <<'EOF'
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: web-gateway
  namespace: gw-demo
spec:
  gatewayClassName: nginx
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
EOF
```{{exec}}

### 5 · Wait for Programmed=True

```bash
kubectl wait gateway web-gateway -n gw-demo \
  --for=condition=Programmed --timeout=120s
kubectl get gateway web-gateway -n gw-demo -o wide
```{{exec}}

## Verify

```bash
kubectl get gatewayclass nginx
kubectl get gateway web-gateway -n gw-demo \
  -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}{"\n"}'
```{{exec}}

<details><summary>Solution</summary>

```bash
# 1 — CRDs
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml

# 2 — NGINX Gateway Fabric
kubectl create namespace nginx-gateway --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f https://raw.githubusercontent.com/nginxinc/nginx-gateway-fabric/v1.4.0/deploy/crds.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/nginx-gateway-fabric/v1.4.0/deploy/default/deploy.yaml
kubectl rollout status deployment nginx-gateway -n nginx-gateway --timeout=120s

# 3 — GatewayClass
kubectl apply -f - <<'EOF'
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: nginx
spec:
  controllerName: gateway.nginx.org/nginx-gateway-controller
EOF

# 4 — Gateway
kubectl apply -f - <<'EOF'
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: web-gateway
  namespace: gw-demo
spec:
  gatewayClassName: nginx
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
EOF

kubectl wait gateway web-gateway -n gw-demo --for=condition=Programmed --timeout=120s
```{{exec}}

</details>
