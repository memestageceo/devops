# Q6 (5%) — Startup + Readiness + Liveness Probes

**Time budget: ~10 min**

## Context

Namespace `probes-lab` contains Deployment `slow-boot` running an app that:

- Takes **45–90 s** to initialize — `/healthz/started` returns 200 only after init completes.
- Returns 503 from `/healthz/ready` briefly during background reloads.
- Should be killed only if `/healthz/live` fails for **30 consecutive seconds**.

## Task

Patch Deployment `slow-boot` to add all three probes. The startup probe must cover up to **2 minutes** of startup time.

```bash
kubectl patch deployment slow-boot -n probes-lab --type=merge -p '
{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "app",
          "startupProbe": {
            "httpGet": {"path": "/healthz/started", "port": 8080},
            "failureThreshold": 24,
            "periodSeconds": 5
          },
          "readinessProbe": {
            "httpGet": {"path": "/healthz/ready", "port": 8080},
            "initialDelaySeconds": 0,
            "periodSeconds": 5,
            "failureThreshold": 3
          },
          "livenessProbe": {
            "httpGet": {"path": "/healthz/live", "port": 8080},
            "periodSeconds": 10,
            "failureThreshold": 3
          }
        }]
      }
    }
  }
}'
```{{exec}}

> **Probe rationale (required comment in real exam):**
> - `startupProbe`: `failureThreshold=24 × periodSeconds=5 = 120 s` → covers up to 2-minute startup; kubelet will not run liveness/readiness until startup succeeds.
> - `readinessProbe`: removes pod from Service endpoints on failure; does **not** restart the pod.
> - `livenessProbe`: `failureThreshold=3 × periodSeconds=10 = 30 s` → kills pod only after 30 consecutive seconds of liveness failure.

## Verify

```bash
kubectl get deployment slow-boot -n probes-lab \
  -o jsonpath='{.spec.template.spec.containers[0].startupProbe}{"\n"}'
kubectl get deployment slow-boot -n probes-lab \
  -o jsonpath='{.spec.template.spec.containers[0].readinessProbe}{"\n"}'
kubectl get deployment slow-boot -n probes-lab \
  -o jsonpath='{.spec.template.spec.containers[0].livenessProbe}{"\n"}'
```{{exec}}

<details><summary>Solution</summary>

Minimum viable probe config that satisfies all constraints:

```yaml
startupProbe:
  httpGet:
    path: /healthz/started
    port: 8080
  failureThreshold: 24   # 24 × 5s = 120s window
  periodSeconds: 5
readinessProbe:
  httpGet:
    path: /healthz/ready
    port: 8080
  periodSeconds: 5
  failureThreshold: 3
livenessProbe:
  httpGet:
    path: /healthz/live
    port: 8080
  periodSeconds: 10
  failureThreshold: 3    # 3 × 10s = 30s before restart
```

</details>
