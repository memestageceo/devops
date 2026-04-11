# Q12 (7%) — Troubleshoot a NotReady Node

**Time budget: ~12 min**

## Context

This step **breaks** the worker node (`node01`) first. Your job is to diagnose and fix it without rebooting.

## Setup — Break the node

Run one of the following commands to introduce a fault (choose one, or have a colleague choose without telling you):

**Option A — Stop and disable kubelet:**
```bash
ssh node01 "sudo systemctl stop kubelet && sudo systemctl disable kubelet"
```{{exec}}

**Option B — Corrupt the kubelet config:**
```bash
ssh node01 "sudo sh -c 'echo \"INVALID: {{{\" >> /var/lib/kubelet/config.yaml'"
```{{exec}}

**Option C — Point kubelet to a wrong container runtime socket:**
```bash
ssh node01 "sudo sed -i 's|containerRuntimeEndpoint:.*|containerRuntimeEndpoint: unix:///run/containerd/WRONG.sock|' /var/lib/kubelet/config.yaml"
```{{exec}}

Confirm the node is NotReady:
```bash
kubectl get nodes
```{{exec}}

---

## Task — Diagnose and fix

### Step 1: Identify the node state

```bash
kubectl describe node node01 | grep -A 10 Conditions
```{{exec}}

### Step 2: SSH and check kubelet

```bash
ssh node01 "sudo systemctl status kubelet"
```{{exec}}

```bash
ssh node01 "sudo journalctl -u kubelet -n 50 --no-pager"
```{{exec}}

### Step 3: Apply the appropriate fix

**If kubelet is stopped/disabled (Option A):**
```bash
ssh node01 "sudo systemctl enable kubelet && sudo systemctl start kubelet"
```{{exec}}

**If config file is corrupted (Option B):**
```bash
ssh node01 "sudo cp /var/lib/kubelet/config.yaml.bak /var/lib/kubelet/config.yaml && \
  sudo systemctl restart kubelet"
```{{exec}}

**If wrong container runtime socket (Option C):**
```bash
ssh node01 "sudo sed -i 's|containerRuntimeEndpoint:.*|containerRuntimeEndpoint: unix:///run/containerd/containerd.sock|' \
  /var/lib/kubelet/config.yaml && sudo systemctl restart kubelet"
```{{exec}}

### Step 4: Confirm node is Ready

```bash
kubectl get nodes --watch
```{{exec}}

```bash
# Press Ctrl-C once node01 shows Ready
```

## Verify

```bash
kubectl get node node01
```{{exec}}

<details><summary>Solution — Diagnosis workflow</summary>

1. `kubectl get nodes` — identify NotReady node
2. `kubectl describe node node01` — check Conditions section for clue
3. `ssh node01 && sudo journalctl -u kubelet -n 100` — read error message
4. Fix based on error:
   - `Failed to connect to CRI endpoint` → wrong socket path in config
   - `failed to load Kubelet config file` → corrupt YAML
   - `kubelet.service could not be found` / `inactive (dead)` → stopped/disabled

Always run `sudo systemctl daemon-reload` before restarting if you edited a unit file.

</details>
