# Q11 (4%) — Native Sidecar Container

**Time budget: ~8 min**

## Context

Namespace `sidecar-lab`. Kubernetes 1.29+ supports native sidecars via init containers with `restartPolicy: Always`.

## Task

Create Deployment `web-with-logger` where:
- Main container: `nginx:1.27`, writes access logs to `/var/log/nginx/access.log` via a shared `emptyDir`.
- Native sidecar: init container with `restartPolicy: Always` running `busybox:1.36`, tailing the log file.
- The sidecar starts **before** nginx and runs for the pod's entire lifetime.

```bash
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-with-logger
  namespace: sidecar-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-with-logger
  template:
    metadata:
      labels:
        app: web-with-logger
    spec:
      initContainers:
      # Native sidecar: restartPolicy: Always keeps it running alongside main containers
      - name: log-tailer
        image: busybox:1.36
        restartPolicy: Always
        command:
        - sh
        - -c
        - |
          # Wait for log file to appear, then tail it
          until [ -f /var/log/nginx/access.log ]; do sleep 1; done
          tail -F /var/log/nginx/access.log
        volumeMounts:
        - name: nginx-logs
          mountPath: /var/log/nginx
      containers:
      - name: nginx
        image: nginx:1.27
        ports:
        - containerPort: 80
        volumeMounts:
        - name: nginx-logs
          mountPath: /var/log/nginx
      volumes:
      - name: nginx-logs
        emptyDir: {}
EOF
```{{exec}}

## Verify

```bash
kubectl rollout status deployment web-with-logger -n sidecar-lab --timeout=60s
```{{exec}}

```bash
# Confirm the init container has restartPolicy=Always (native sidecar)
kubectl get deployment web-with-logger -n sidecar-lab \
  -o jsonpath='{.spec.template.spec.initContainers[0].restartPolicy}{"\n"}'
```{{exec}}

```bash
# Both containers should be Running in the same pod
kubectl get pod -n sidecar-lab -l app=web-with-logger \
  -o jsonpath='{range .items[0].status.containerStatuses[*]}{.name}: {.state}{"\n"}{end}'
```{{exec}}

```bash
# Generate a log entry then check the sidecar output
POD=$(kubectl get pod -n sidecar-lab -l app=web-with-logger -o name | head -1)
kubectl exec -n sidecar-lab "$POD" -c nginx -- curl -s http://localhost/
kubectl logs -n sidecar-lab "$POD" -c log-tailer --tail=5
```{{exec}}

<details><summary>Solution</summary>

The key field is `restartPolicy: Always` on the init container. This upgrades it from a regular init container (which runs once and exits) to a **sidecar** that starts before the main containers and is restarted if it exits, lasting the full lifetime of the pod.

Kubernetes docs: [Sidecar Containers](https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/)

</details>
