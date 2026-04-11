# Q3 (7%) — CNI: Replace with Cilium

**Time budget: ~15 min**

> ⚠️ This question replaces the cluster CNI. Complete it carefully; the cluster will be briefly disrupted.

## Context

The cluster runs an existing CNI. You will replace it with Cilium.

## Task

### 1 · Drain the worker node

```bash
kubectl drain node01 --ignore-daemonsets --delete-emptydir-data
```{{exec}}

### 2 · Remove the existing CNI on node01

SSH to `node01` and remove existing CNI config and binaries:

```bash
ssh node01 "sudo rm -f /etc/cni/net.d/* && \
  sudo find /opt/cni/bin/ -maxdepth 1 -type f \
    ! -name 'loopback' ! -name 'portmap' ! -name 'bandwidth' -delete"
```{{exec}}

### 3 · Install Cilium CLI on the controlplane

```bash
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
curl -L --silent --remote-name-all \
  "https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-amd64.tar.gz"
tar xzvf cilium-linux-amd64.tar.gz -C /usr/local/bin
rm cilium-linux-amd64.tar.gz
cilium version --client
```{{exec}}

### 4 · Remove the existing CNI DaemonSet (if present)

```bash
# Remove flannel if present
kubectl delete -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml \
  --ignore-not-found
# Or remove weave if present
kubectl delete daemonset weave-net -n kube-system --ignore-not-found
```{{exec}}

### 5 · Install Cilium

```bash
cilium install --version 1.15.4
cilium status --wait
```{{exec}}

### 6 · Uncordon node01 and verify both nodes are Ready

```bash
kubectl uncordon node01
kubectl get nodes
```{{exec}}

### 7 · Enable Hubble

```bash
cilium hubble enable
cilium status
```{{exec}}

### 8 · Verify pod-to-pod connectivity across nodes

```bash
kubectl run pod-cp --image=busybox:1.36 --overrides='{"spec":{"nodeName":"controlplane"}}' \
  --restart=Never -- sleep 3600
kubectl run pod-w --image=busybox:1.36 --overrides='{"spec":{"nodeName":"node01"}}' \
  --restart=Never -- sleep 3600
kubectl wait pod pod-cp pod-w --for=condition=Ready --timeout=60s

POD_W_IP=$(kubectl get pod pod-w -o jsonpath='{.status.podIP}')
kubectl exec pod-cp -- ping -c 3 "$POD_W_IP"
```{{exec}}

```bash
# Cleanup test pods
kubectl delete pod pod-cp pod-w --ignore-not-found
```{{exec}}

## Verify

```bash
kubectl get nodes
kubectl get daemonset cilium -n kube-system
cilium status
```{{exec}}

<details><summary>Solution</summary>

The key steps are:
1. `kubectl drain node01 --ignore-daemonsets --delete-emptydir-data`
2. Remove old CNI files on node01 via SSH
3. Install Cilium CLI, run `cilium install`, then `cilium hubble enable`
4. `kubectl uncordon node01` and confirm both nodes `Ready`

Cilium docs: [https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/)

</details>
