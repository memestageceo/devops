# CKA 2025 — Mock Practice Set

> Solve on your 2-node kubeadm cluster. Each question lists a *Context* (namespace / setup) and a *Task*. Weights mimic the real exam. Don't peek at docs you wouldn't have on exam day — only `kubernetes.io/docs`, `kubernetes.io/blog`, `gateway-api.sigs.k8s.io`, and `helm.sh/docs` are allowed.

---

## Question 1 — Gateway API: Install & Basic Routing  *(Weight: 8%)*

**Context:** No Gateway API CRDs are installed on your cluster yet.

**Task:**
1. Install the **Gateway API standard channel CRDs** (v1.2.0 or later).
2. Install **NGINX Gateway Fabric** (or any conformant implementation of your choice) into the namespace `nginx-gateway`.
3. Create a `GatewayClass` named `nginx` that points to the controller you installed.
4. In namespace `gw-demo`, create a `Gateway` named `web-gateway` listening on port `80`, protocol `HTTP`, with `allowedRoutes.namespaces.from: Same`.
5. Verify the Gateway reaches `Programmed=True`.

---

## Question 2 — HTTPRoute Traffic Splitting  *(Weight: 7%)*

**Context:** Use the `gw-demo` namespace and the `web-gateway` from Q1. Two Deployments already exist (create them if not): `app-v1` and `app-v2`, each fronted by ClusterIP services `app-v1-svc` and `app-v2-svc` on port 80.

**Task:**
- Create an `HTTPRoute` named `app-route` attached to `web-gateway` such that:
  - Requests to host `app.local` with path prefix `/` are split **80/20** between `app-v1-svc` and `app-v2-svc`.
  - Requests with header `x-canary: true` go **100% to `app-v2-svc`** regardless of weight.
- Verify with `curl -H "Host: app.local" ...` from inside a debug pod.

---

## Question 3 — CNI Installation from Scratch  *(Weight: 7%)*

**Context:** Drain `node02`, then on that node delete `/etc/cni/net.d/*` and any existing CNI binaries under `/opt/cni/bin/` belonging to the current CNI. The node will go `NotReady`.

**Task:**
- Replace the current CNI on the cluster with **Cilium** (any recent stable version) using the Cilium CLI or Helm.
- Ensure both nodes return to `Ready`.
- Confirm pod-to-pod connectivity across nodes using two test pods (one pinned to each node via `nodeName`).
- Enable **Hubble** (relay + UI not required, just the observability layer) and show flows for the test traffic.

---

## Question 4 — Node-Level Kubelet Configuration  *(Weight: 6%)*

**Context:** SSH to `node02`.

**Task:**
1. Reconfigure the kubelet on `node02` so that:
   - `maxPods` is set to `80`
   - `evictionHard.memory.available` is `200Mi`
   - `systemReserved.cpu` is `200m` and `systemReserved.memory` is `300Mi`
2. Persist the changes via the kubelet config file (not flags).
3. Restart kubelet cleanly and confirm the new values are reflected in `kubectl get --raw "/api/v1/nodes/node02/proxy/configz"`.

---

## Question 5 — HPA on Custom Metrics  *(Weight: 8%)*

**Context:** Namespace `metrics-demo`. A Deployment `orders-api` exposes a Prometheus metric `orders_in_flight` on `/metrics` port `8080`.

**Task:**
1. Install **Prometheus** + **prometheus-adapter** (Helm is fine) so that `orders_in_flight` is exposed via the `custom.metrics.k8s.io` API as a Pods metric named `orders_in_flight`.
2. Create an `HorizontalPodAutoscaler` named `orders-hpa` that scales `orders-api` between `2` and `10` replicas, targeting an **average value of `30` `orders_in_flight` per pod**.
3. Verify with `kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/metrics-demo/pods/*/orders_in_flight"`.

> If you don't have an `orders-api` image, write a tiny one in any language that increments/decrements the gauge based on a query param, or use `nginxinc/nginx-prometheus-exporter` patterns.

---

## Question 6 — Probes: Startup + Readiness + Liveness  *(Weight: 5%)*

**Context:** Namespace `probes-lab`. A Deployment `slow-boot` runs an app that:
- Takes **45–90 seconds** to fully initialize (`/healthz/started` returns 200 only after init)
- Briefly returns 503 from `/healthz/ready` during background reloads
- Should be killed if `/healthz/live` fails for **30 consecutive seconds**

**Task:**
- Configure `startupProbe`, `readinessProbe`, and `livenessProbe` such that:
  - The pod is **never killed during the slow startup window**, even if startup takes up to 2 minutes.
  - The pod is removed from Service endpoints during reloads but **not restarted**.
  - Liveness only triggers a restart after sustained failure.
- Use HTTP probes. Justify your `failureThreshold` and `periodSeconds` choices in a comment inside the manifest.

---

## Question 7 — Projected Volume  *(Weight: 5%)*

**Context:** Namespace `proj-vol`.

**Task:**
Create a Pod `audit-agent` (image: `busybox:1.36`, command: `sleep 3600`) that mounts a **single projected volume** at `/etc/agent/` containing:
1. A ConfigMap `agent-config` (key `agent.yaml`) → projected as `config/agent.yaml`
2. A Secret `agent-creds` (keys `username`, `password`) → projected as `secrets/username` and `secrets/password`
3. A **service account token** with audience `vault` and `expirationSeconds: 3600` → projected as `token`
4. Downward API: the pod's `metadata.labels` → projected as `meta/labels`

Create the ConfigMap and Secret with any sample data. Verify all four are present inside the pod.

---

## Question 8 — etcd Backup & Restore  *(Weight: 8%)*

**Context:** Your control plane runs etcd as a static pod. SSH to the control-plane node.

**Task:**
1. Take a snapshot of etcd to `/opt/backups/etcd-snap-$(date +%s).db` using `etcdctl` with the correct cert/endpoint flags.
2. Now create a new namespace `will-be-lost` with a ConfigMap `marker` containing `key=before-restore`.
3. **Restore** etcd from the snapshot you took *before* creating that namespace into a new data dir `/var/lib/etcd-restored`.
4. Reconfigure the static pod manifest to use the restored data dir.
5. Verify the cluster is healthy and that `will-be-lost` namespace **no longer exists**.

---

## Question 9 — PV / PVC with Specific Mount Options  *(Weight: 5%)*

**Context:** Namespace `storage-lab`. On `node01`, create directory `/srv/data/app1` with `chmod 0775`.

**Task:**
- Create a `PersistentVolume` named `app1-pv`:
  - Capacity: `2Gi`
  - Access mode: `ReadWriteOnce`
  - `hostPath` at `/srv/data/app1`
  - `persistentVolumeReclaimPolicy: Retain`
  - Node affinity that **binds it strictly to `node01`**
- Create a `PersistentVolumeClaim` `app1-pvc` (1Gi, RWO) that binds to it.
- Create a Deployment `writer` (1 replica, image `busybox:1.36`) that:
  - Runs `sh -c 'while true; do date >> /data/log; sleep 5; done'`
  - Mounts the PVC at `/data`
  - Is forced to schedule on `node01`

---

## Question 10 — NetworkPolicy: Default-Deny + Selective Allow  *(Weight: 6%)*

**Context:** Namespace `np-lab` already has three Deployments: `frontend`, `backend`, `db`, each with a matching Service on port `80` (db on `5432`).

**Task:**
1. Apply a **default-deny** policy for all ingress AND egress in `np-lab`.
2. Allow `frontend → backend` on port `80`.
3. Allow `backend → db` on port `5432`.
4. Allow **all pods** in `np-lab` egress to `kube-dns` in `kube-system` on UDP/TCP `53`.
5. Allow `frontend` ingress from any pod in a namespace labeled `purpose=ingress`.

Verify with `kubectl exec` + `wget`/`nc` from each tier.

---

## Question 11 — Sidecar (Native) Container  *(Weight: 4%)*

**Context:** Namespace `sidecar-lab`.

**Task:**
Create a Deployment `web-with-logger` where:
- The main container is `nginx:1.27` writing access logs to `/var/log/nginx/access.log` (use an `emptyDir` mounted at `/var/log/nginx`).
- A **native sidecar** (i.e. an init container with `restartPolicy: Always`) runs `busybox:1.36` and tails `/var/log/nginx/access.log`, sharing the same emptyDir.
- The sidecar must start **before** nginx is considered ready and must continue running for the lifetime of the pod.

---

## Question 12 — Troubleshoot a NotReady Node  *(Weight: 7%)*

**Context:** Before starting, deliberately break `node02` by doing **one** of (pick one without telling yourself which until later, or have a friend do it):
- `systemctl stop kubelet` and disable it
- Corrupt `/var/lib/kubelet/config.yaml` (e.g. invalid YAML)
- Change the container runtime endpoint in kubelet config to a wrong socket path

**Task:**
- Diagnose why `node02` is `NotReady`.
- Fix it. Document each command you ran and what it told you.
- Bring `node02` back to `Ready` without rebooting the VM.

---

## Question 13 — kubeadm Upgrade  *(Weight: 8%)*

**Context:** Your cluster is on some version `vX.Y.Z`. Identify it.

**Task:**
1. Upgrade the **control-plane node** to the next minor version (`vX.(Y+1).0` or latest patch of that minor).
2. Upgrade `node02` (worker) to the same version.
3. Follow the proper drain/uncordon sequence.
4. Verify all system pods are healthy and both nodes report the new version.

> Snapshot your VMs first.

---

## Question 14 — RBAC: Scoped ServiceAccount  *(Weight: 5%)*

**Context:** Namespace `rbac-lab`.

**Task:**
1. Create a ServiceAccount `deploy-bot` in `rbac-lab`.
2. Grant it **only** these permissions, namespace-scoped:
   - `get`, `list`, `watch`, `create`, `update`, `patch` on `deployments` and `replicasets` in `apps`
   - `get`, `list` on `pods` and `pods/log` in core
   - `create` on `events` in core
3. Generate a **bound ServiceAccount token** valid for 1 hour using `kubectl create token`.
4. Use that token with `kubectl --token=...` to confirm:
   - It **can** list deployments in `rbac-lab`
   - It **cannot** delete a deployment
   - It **cannot** list pods in `kube-system`

---

## Question 15 — Scheduling: Taints, Tolerations & Topology Spread  *(Weight: 6%)*

**Context:** Namespace `sched-lab`.

**Task:**
1. Taint `node01` with `workload=critical:NoSchedule`.
2. Label both nodes with `zone=a` (`node01`) and `zone=b` (`node02`).
3. Create a Deployment `critical-app` with **4 replicas** (image `nginx:1.27`) such that:
   - Pods tolerate the `workload=critical:NoSchedule` taint.
   - Pods are **evenly spread across zones** (`maxSkew: 1`, `whenUnsatisfiable: DoNotSchedule`).
   - Pods prefer (soft) **not** to be co-located with another `critical-app` pod on the same node.
4. Verify the resulting placement.

---

## Suggested time budget

Real CKA gives you ~2 hours for ~15–20 questions. Try to finish this set in **2h 15m**. If you blow past 15 minutes on any single question, flag it and move on — exactly what you'd do on exam day.

## After you finish

For each question, write down:
- Time taken
- Whether you needed docs and which page
- One thing you'd do faster next time

That post-mortem is where most of the score improvement actually comes from.
