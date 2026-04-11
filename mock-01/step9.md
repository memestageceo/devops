# Q9 (5%) — PV / PVC with hostPath

**Time budget: ~10 min**

## Context

Namespace `storage-lab`. Directory `/srv/data/app1` already exists on `controlplane` with permissions `0775`.

> **Node mapping:** "node01" in the question = `controlplane` in this environment.

## Task

### 1 · Create the PersistentVolume

```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: PersistentVolume
metadata:
  name: app1-pv
spec:
  capacity:
    storage: 2Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /srv/data/app1
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - controlplane
EOF
```{{exec}}

### 2 · Create the PersistentVolumeClaim

```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app1-pvc
  namespace: storage-lab
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF
```{{exec}}

```bash
kubectl get pv app1-pv
kubectl get pvc app1-pvc -n storage-lab
```{{exec}}

### 3 · Create the writer Deployment

```bash
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: writer
  namespace: storage-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: writer
  template:
    metadata:
      labels:
        app: writer
    spec:
      nodeName: controlplane
      containers:
      - name: writer
        image: busybox:1.36
        command:
        - sh
        - -c
        - while true; do date >> /data/log; sleep 5; done
        volumeMounts:
        - name: data
          mountPath: /data
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: app1-pvc
EOF
```{{exec}}

### 4 · Verify

```bash
kubectl rollout status deployment writer -n storage-lab --timeout=60s
kubectl exec -n storage-lab deployment/writer -- tail -5 /data/log
```{{exec}}

<details><summary>Solution</summary>

Key points:
- `nodeAffinity` on the PV uses `kubernetes.io/hostname: controlplane` to restrict binding.
- The Deployment uses `nodeName: controlplane` to force scheduling.
- `persistentVolumeReclaimPolicy: Retain` means the PV is not deleted when the PVC is removed.

</details>
