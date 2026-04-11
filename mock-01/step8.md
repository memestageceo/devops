# Q8 (8%) — etcd Backup & Restore

**Time budget: ~15 min**

> ⚠️ This question modifies the etcd data directory used by the control-plane static pod. Follow the steps carefully.

## Context

etcd runs as a static pod on the controlplane. All commands run on the controlplane node.

## Task

### 1 · Identify etcd cert paths and endpoint

```bash
grep -E 'listen-client-urls|cert-file|key-file|trusted-ca-file' \
  /etc/kubernetes/manifests/etcd.yaml
```{{exec}}

### 2 · Take a snapshot

```bash
ETCD_SNAP="/opt/backups/etcd-snap-$(date +%s).db"
ETCDCTL_API=3 etcdctl snapshot save "$ETCD_SNAP" \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
echo "Saved to $ETCD_SNAP"
ETCDCTL_API=3 etcdctl snapshot status "$ETCD_SNAP" --write-out=table
```{{exec}}

### 3 · Create a resource that will disappear after restore

```bash
kubectl create namespace will-be-lost
kubectl create configmap marker --from-literal=key=before-restore -n will-be-lost
kubectl get configmap marker -n will-be-lost
```{{exec}}

### 4 · Restore the snapshot to a new data directory

```bash
ETCD_SNAP=$(ls -t /opt/backups/etcd-snap-*.db | head -1)
ETCDCTL_API=3 etcdctl snapshot restore "$ETCD_SNAP" \
  --data-dir=/var/lib/etcd-restored
ls /var/lib/etcd-restored
```{{exec}}

### 5 · Reconfigure the static pod to use the restored data directory

```bash
# Back up the manifest first
cp /etc/kubernetes/manifests/etcd.yaml /etc/kubernetes/manifests/etcd.yaml.bak

# Update the --data-dir flag and the hostPath volume
sed -i 's|/var/lib/etcd|/var/lib/etcd-restored|g' \
  /etc/kubernetes/manifests/etcd.yaml

grep 'etcd-restored' /etc/kubernetes/manifests/etcd.yaml
```{{exec}}

The kubelet will detect the manifest change and restart etcd automatically. Wait for it:

```bash
# etcd pod disappears then reappears — wait up to 90 s
sleep 10
kubectl wait pod -n kube-system -l component=etcd \
  --for=condition=Ready --timeout=90s
```{{exec}}

### 6 · Verify restore was successful

```bash
kubectl get namespaces
kubectl get namespace will-be-lost 2>&1 || echo "Confirmed: will-be-lost is gone"
```{{exec}}

<details><summary>Solution</summary>

Key commands:
```bash
# Backup
ETCDCTL_API=3 etcdctl snapshot save /opt/backups/etcd-snap-$(date +%s).db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Restore
ETCDCTL_API=3 etcdctl snapshot restore <snap.db> --data-dir=/var/lib/etcd-restored

# Update manifest
sed -i 's|/var/lib/etcd|/var/lib/etcd-restored|g' /etc/kubernetes/manifests/etcd.yaml
```

After the manifest update, kubelet restarts etcd automatically. The cluster should recover within ~60 s.

</details>
