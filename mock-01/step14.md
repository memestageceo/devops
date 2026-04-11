# Q14 (5%) — RBAC: Scoped ServiceAccount

**Time budget: ~10 min**

## Context

Namespace `rbac-lab`.

## Task

### 1 · Create the ServiceAccount

```bash
kubectl create serviceaccount deploy-bot -n rbac-lab
```{{exec}}

### 2 · Create the Role

```bash
kubectl apply -f - <<'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deploy-bot-role
  namespace: rbac-lab
rules:
# deployments + replicasets in apps
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
# pods + pods/log in core
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list"]
# events in core
- apiGroups: [""]
  resources: ["events"]
  verbs: ["create"]
EOF
```{{exec}}

### 3 · Create the RoleBinding

```bash
kubectl create rolebinding deploy-bot-binding \
  --role=deploy-bot-role \
  --serviceaccount=rbac-lab:deploy-bot \
  --namespace=rbac-lab
```{{exec}}

### 4 · Generate a bound token (valid 1 hour)

```bash
TOKEN=$(kubectl create token deploy-bot -n rbac-lab --duration=1h)
echo "$TOKEN" | cut -c1-60
echo "...(token truncated)"
```{{exec}}

### 5 · Verify permissions

```bash
TOKEN=$(kubectl create token deploy-bot -n rbac-lab --duration=1h)

echo "--- CAN list deployments in rbac-lab ---"
kubectl --token="$TOKEN" get deployments -n rbac-lab

echo "--- CANNOT delete a deployment ---"
kubectl --token="$TOKEN" delete deployment nonexistent -n rbac-lab 2>&1 || true

echo "--- CANNOT list pods in kube-system ---"
kubectl --token="$TOKEN" get pods -n kube-system 2>&1 || true
```{{exec}}

## Verify

```bash
kubectl get serviceaccount deploy-bot -n rbac-lab
kubectl get role deploy-bot-role -n rbac-lab -o yaml
kubectl get rolebinding deploy-bot-binding -n rbac-lab -o yaml
```{{exec}}

```bash
kubectl auth can-i list deployments --as=system:serviceaccount:rbac-lab:deploy-bot -n rbac-lab
kubectl auth can-i delete deployments --as=system:serviceaccount:rbac-lab:deploy-bot -n rbac-lab
kubectl auth can-i list pods --as=system:serviceaccount:rbac-lab:deploy-bot -n kube-system
```{{exec}}

<details><summary>Solution</summary>

```bash
kubectl create serviceaccount deploy-bot -n rbac-lab

kubectl apply -f - <<'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deploy-bot-role
  namespace: rbac-lab
rules:
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["events"]
  verbs: ["create"]
EOF

kubectl create rolebinding deploy-bot-binding \
  --role=deploy-bot-role \
  --serviceaccount=rbac-lab:deploy-bot \
  -n rbac-lab

kubectl create token deploy-bot -n rbac-lab --duration=1h
```{{exec}}

</details>
