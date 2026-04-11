# Q15 (6%) — Taints, Tolerations & Topology Spread

**Time budget: ~12 min**

## Context

Namespace `sched-lab`.

> **Node mapping:** controlplane = zone A, node01 (worker) = zone B.

## Task

### 1 · Taint the controlplane

```bash
kubectl taint node controlplane workload=critical:NoSchedule
kubectl describe node controlplane | grep Taints
```{{exec}}

### 2 · Label both nodes with zone

```bash
kubectl label node controlplane zone=a
kubectl label node node01 zone=b
kubectl get nodes --show-labels | grep zone
```{{exec}}

### 3 · Create the Deployment with tolerations and topology spread

```bash
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: critical-app
  namespace: sched-lab
spec:
  replicas: 4
  selector:
    matchLabels:
      app: critical-app
  template:
    metadata:
      labels:
        app: critical-app
    spec:
      tolerations:
      # Tolerate the taint on controlplane
      - key: workload
        value: critical
        effect: NoSchedule

      topologySpreadConstraints:
      # Hard: spread evenly across zones (maxSkew=1)
      - maxSkew: 1
        topologyKey: zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: critical-app

      affinity:
        podAntiAffinity:
          # Soft: prefer not co-locating on the same node
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              topologyKey: kubernetes.io/hostname
              labelSelector:
                matchLabels:
                  app: critical-app

      containers:
      - name: app
        image: nginx:1.27
        ports:
        - containerPort: 80
EOF
```{{exec}}

### 4 · Verify placement

```bash
kubectl rollout status deployment critical-app -n sched-lab --timeout=60s
```{{exec}}

```bash
kubectl get pods -n sched-lab -o wide
```{{exec}}

You should see pods distributed across both nodes (2 per node given 4 replicas and 2 zones).

<details><summary>Solution</summary>

Key spec elements:
- `tolerations` with `key: workload`, `value: critical`, `effect: NoSchedule` — allows scheduling on the tainted controlplane.
- `topologySpreadConstraints` with `topologyKey: zone`, `maxSkew: 1`, `whenUnsatisfiable: DoNotSchedule` — enforces even spread across zones.
- `podAntiAffinity.preferredDuring...` with `topologyKey: kubernetes.io/hostname` — soft preference against co-location.

Without the toleration, all 4 pods land on the worker. Without topology spread, distribution is not guaranteed.

</details>
