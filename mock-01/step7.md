# Q7 (5%) — Projected Volume

**Time budget: ~10 min**

## Context

Namespace `proj-vol`.

## Task

Create a ConfigMap, Secret, and Pod `audit-agent` (image: `busybox:1.36`, `sleep 3600`) with a **single projected volume** at `/etc/agent/` containing all four sources.

### 1 · Create the ConfigMap and Secret

```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: agent-config
  namespace: proj-vol
data:
  agent.yaml: |
    log_level: info
    endpoint: https://vault.example.com
---
apiVersion: v1
kind: Secret
metadata:
  name: agent-creds
  namespace: proj-vol
stringData:
  username: audit-svc
  password: s3cr3t!
EOF
```{{exec}}

### 2 · Create the Pod with the projected volume

```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: audit-agent
  namespace: proj-vol
  labels:
    app: audit-agent
    env: exam
spec:
  serviceAccountName: default
  containers:
  - name: agent
    image: busybox:1.36
    command: ["sleep", "3600"]
    volumeMounts:
    - name: projected
      mountPath: /etc/agent
  volumes:
  - name: projected
    projected:
      sources:
      # 1 — ConfigMap key → config/agent.yaml
      - configMap:
          name: agent-config
          items:
          - key: agent.yaml
            path: config/agent.yaml
      # 2 — Secret keys → secrets/username, secrets/password
      - secret:
          name: agent-creds
          items:
          - key: username
            path: secrets/username
          - key: password
            path: secrets/password
      # 3 — Service account token with audience=vault
      - serviceAccountToken:
          audience: vault
          expirationSeconds: 3600
          path: token
      # 4 — Downward API: pod labels
      - downwardAPI:
          items:
          - path: meta/labels
            fieldRef:
              fieldPath: metadata.labels
EOF
```{{exec}}

### 3 · Wait and verify

```bash
kubectl wait pod audit-agent -n proj-vol --for=condition=Ready --timeout=60s
```{{exec}}

```bash
kubectl exec audit-agent -n proj-vol -- sh -c \
  "ls /etc/agent/config/ /etc/agent/secrets/ && \
   cat /etc/agent/token | cut -c1-20 && echo '...(token)' && \
   cat /etc/agent/meta/labels"
```{{exec}}

<details><summary>Solution</summary>

The projected volume combines four `sources` in a single `volumes` entry:

1. `configMap` with `items` to control the path
2. `secret` with `items` for each key
3. `serviceAccountToken` with `audience`, `expirationSeconds`, and `path`
4. `downwardAPI` with a `fieldRef` for `metadata.labels`

All four mount under the same `mountPath: /etc/agent`.

</details>
