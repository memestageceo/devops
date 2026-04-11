# Q13 (8%) — kubeadm Cluster Upgrade

**Time budget: ~15 min**

> ⚠️ Snapshot your environment before starting. An upgrade cannot be undone.

## Context

Identify the current cluster version, then upgrade both nodes to the next minor version.

## Task

### 1 · Identify current version and available upgrades

```bash
kubectl get nodes
kubeadm version
kubeadm upgrade plan
```{{exec}}

### 2 · Upgrade the controlplane node

```bash
# Determine the target version from `kubeadm upgrade plan` output, e.g. v1.32.0
TARGET_VERSION="1.32.0"   # ← adjust to actual next minor

# Update kubeadm package
apt-get update && apt-get install -y --allow-change-held-packages kubeadm=${TARGET_VERSION}-1.1
kubeadm version
```{{exec}}

```bash
# Verify the upgrade plan
kubeadm upgrade plan v${TARGET_VERSION}
```{{exec}}

```bash
# Apply the upgrade
kubeadm upgrade apply v${TARGET_VERSION} --yes
```{{exec}}

```bash
# Drain controlplane
kubectl drain controlplane --ignore-daemonsets --delete-emptydir-data
```{{exec}}

```bash
# Upgrade kubelet and kubectl on controlplane
apt-get install -y --allow-change-held-packages \
  kubelet=${TARGET_VERSION}-1.1 kubectl=${TARGET_VERSION}-1.1
systemctl daemon-reload && systemctl restart kubelet
```{{exec}}

```bash
# Uncordon controlplane
kubectl uncordon controlplane
kubectl get nodes
```{{exec}}

### 3 · Upgrade the worker node (node01)

```bash
# Drain the worker
kubectl drain node01 --ignore-daemonsets --delete-emptydir-data
```{{exec}}

```bash
# SSH to node01 and upgrade kubeadm + kubelet + kubectl
ssh node01 "sudo apt-get update && \
  sudo apt-get install -y --allow-change-held-packages \
  kubeadm=${TARGET_VERSION}-1.1 kubelet=${TARGET_VERSION}-1.1 kubectl=${TARGET_VERSION}-1.1 && \
  sudo kubeadm upgrade node && \
  sudo systemctl daemon-reload && sudo systemctl restart kubelet"
```{{exec}}

```bash
# Uncordon the worker
kubectl uncordon node01
kubectl get nodes
```{{exec}}

### 4 · Verify

```bash
kubectl get nodes
kubectl get pods -n kube-system
```{{exec}}

<details><summary>Solution</summary>

Upgrade sequence (always controlplane first):
1. `apt-get install kubeadm=<version>` → `kubeadm upgrade apply <version>`
2. Drain → upgrade kubelet/kubectl → uncordon (controlplane)
3. Drain → SSH → `kubeadm upgrade node` → upgrade kubelet/kubectl → uncordon (worker)

On worker nodes, `kubeadm upgrade node` (not `apply`) is used.

Kubernetes docs: [Upgrading kubeadm clusters](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/)

</details>
