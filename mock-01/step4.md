# Q4 (6%) — Node-Level Kubelet Configuration

**Time budget: ~10 min**

## Context

Configure the kubelet on the worker node (`node01`) via its config file (not flags).

## Task

### 1 · SSH to node01 and locate the kubelet config file

```bash
ssh node01
```{{exec}}

```bash
# Find the config file path from the kubelet service
systemctl cat kubelet | grep '\-\-config'
# Typically: /var/lib/kubelet/config.yaml
```{{exec}}

### 2 · Edit the kubelet config

```bash
ssh node01 "sudo cp /var/lib/kubelet/config.yaml /var/lib/kubelet/config.yaml.bak"
```{{exec}}

Apply the three required settings:

```bash
ssh node01 "sudo python3 -c \"
import yaml, sys

with open('/var/lib/kubelet/config.yaml') as f:
    cfg = yaml.safe_load(f)

cfg['maxPods'] = 80
cfg.setdefault('evictionHard', {})['memory.available'] = '200Mi'
cfg.setdefault('systemReserved', {})['cpu'] = '200m'
cfg['systemReserved']['memory'] = '300Mi'

with open('/var/lib/kubelet/config.yaml', 'w') as f:
    yaml.dump(cfg, f, default_flow_style=False)

print('Done')
\""
```{{exec}}

Alternatively, edit by hand:

```bash
ssh node01 "sudo vi /var/lib/kubelet/config.yaml"
```{{exec}}

Verify the file looks correct before restarting:

```bash
ssh node01 "grep -E 'maxPods|memory.available|systemReserved' /var/lib/kubelet/config.yaml"
```{{exec}}

### 3 · Restart kubelet

```bash
ssh node01 "sudo systemctl daemon-reload && sudo systemctl restart kubelet"
ssh node01 "sudo systemctl is-active kubelet"
```{{exec}}

### 4 · Confirm via the configz API

```bash
kubectl get --raw "/api/v1/nodes/node01/proxy/configz" | \
  python3 -m json.tool | grep -E 'maxPods|memory.available|systemReserved' -A2
```{{exec}}

## Verify

```bash
kubectl get --raw "/api/v1/nodes/node01/proxy/configz" | \
  python3 -c "import sys,json; d=json.load(sys.stdin)['kubeletconfig']; \
  print('maxPods:', d.get('maxPods')); \
  print('evictionHard:', d.get('evictionHard',{}).get('memory.available')); \
  print('systemReserved:', d.get('systemReserved'))"
```{{exec}}

<details><summary>Solution</summary>

The kubelet config file is `/var/lib/kubelet/config.yaml`. Add or update:

```yaml
maxPods: 80
evictionHard:
  memory.available: "200Mi"
  # keep any existing entries
systemReserved:
  cpu: "200m"
  memory: "300Mi"
```

Then: `sudo systemctl daemon-reload && sudo systemctl restart kubelet`

Verify: `kubectl get --raw "/api/v1/nodes/node01/proxy/configz" | python3 -m json.tool`

</details>
