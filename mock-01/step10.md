# Q10 (6%) — NetworkPolicy: Default-Deny + Selective Allow

**Time budget: ~12 min**

## Context

Namespace `np-lab` has Deployments `frontend`, `backend`, `db` with matching ClusterIP Services (frontend/backend on port 80, db on port 5432).

## Task

Apply five NetworkPolicies implementing the required topology.

```bash
kubectl apply -f - <<'EOF'
# 1 — Default deny all ingress AND egress in np-lab
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: np-lab
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
# 2 — Allow frontend → backend on port 80
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: np-lab
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 80
---
# 3 — Allow backend → db on port 5432
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-to-db
  namespace: np-lab
spec:
  podSelector:
    matchLabels:
      app: db
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 5432
---
# 4 — Allow all pods in np-lab to egress DNS (kube-system, UDP+TCP 53)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-dns
  namespace: np-lab
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
---
# 5 — Allow frontend ingress from any pod in a namespace labeled purpose=ingress
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-to-frontend
  namespace: np-lab
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          purpose: ingress
EOF
```{{exec}}

## Verify

List all policies:

```bash
kubectl get networkpolicy -n np-lab
```{{exec}}

Test connectivity (frontend → backend should succeed after adding egress allow):

```bash
FRONTEND_POD=$(kubectl get pod -n np-lab -l app=frontend -o name | head -1)
BACKEND_IP=$(kubectl get svc backend -n np-lab -o jsonpath='{.spec.clusterIP}')
kubectl exec -n np-lab "$FRONTEND_POD" -- wget -qO- --timeout=3 "http://${BACKEND_IP}" && \
  echo "frontend→backend: OK" || echo "frontend→backend: BLOCKED (add egress allow rule)"
```{{exec}}

> Note: To allow frontend to reach backend you also need an egress rule on frontend allowing port 80. The policies above are a starting point — extend `allow-egress-dns` or add a dedicated egress-to-backend policy as needed.

<details><summary>Solution</summary>

The five required policies are shown above. Remember that NetworkPolicy is additive — you need both an egress rule on the source pod AND an ingress rule on the destination pod for traffic to flow. The default-deny blocks everything; each `allow-*` policy selectively opens a path.

</details>
