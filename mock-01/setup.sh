#!/bin/bash
# Background setup script — runs on the controlplane node while the intro page is displayed.
set -e

# ── Namespaces ──────────────────────────────────────────────────────────────
for ns in gw-demo metrics-demo probes-lab proj-vol storage-lab np-lab sidecar-lab sched-lab rbac-lab; do
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
done

# ── Q8 prereq: backup directory ──────────────────────────────────────────────
mkdir -p /opt/backups

# ── Q9 prereq: hostPath directory on controlplane ───────────────────────────
mkdir -p /srv/data/app1
chmod 0775 /srv/data/app1

# ── Q2 prereq: app-v1 and app-v2 Deployments + Services in gw-demo ──────────
kubectl apply -f - >/dev/null <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-v1
  namespace: gw-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app-v1
  template:
    metadata:
      labels:
        app: app-v1
    spec:
      containers:
      - name: app
        image: nginx:1.27
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: app-v1-svc
  namespace: gw-demo
spec:
  selector:
    app: app-v1
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-v2
  namespace: gw-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app-v2
  template:
    metadata:
      labels:
        app: app-v2
    spec:
      containers:
      - name: app
        image: nginx:1.27
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: app-v2-svc
  namespace: gw-demo
spec:
  selector:
    app: app-v2
  ports:
  - port: 80
    targetPort: 80
EOF

# ── Q5 prereq: orders-api Deployment in metrics-demo ────────────────────────
kubectl apply -f - >/dev/null <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: orders-api-script
  namespace: metrics-demo
data:
  server.py: |
    import http.server, socketserver, random
    class H(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            if self.path == '/metrics':
                v = random.randint(15, 45)
                body = (
                    '# HELP orders_in_flight Orders currently being processed\n'
                    '# TYPE orders_in_flight gauge\n'
                    f'orders_in_flight {v}\n'
                )
                self.send_response(200)
                self.send_header('Content-Type', 'text/plain; version=0.0.4')
                self.end_headers()
                self.wfile.write(body.encode())
            else:
                self.send_response(200)
                self.end_headers()
        def log_message(self, *a): pass
    with socketserver.TCPServer(('', 8080), H) as s:
        s.serve_forever()
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: orders-api
  namespace: metrics-demo
  labels:
    app: orders-api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: orders-api
  template:
    metadata:
      labels:
        app: orders-api
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: orders-api
        image: python:3.11-slim
        command: ["python3", "/app/server.py"]
        ports:
        - name: metrics
          containerPort: 8080
        volumeMounts:
        - name: script
          mountPath: /app
      volumes:
      - name: script
        configMap:
          name: orders-api-script
---
apiVersion: v1
kind: Service
metadata:
  name: orders-api
  namespace: metrics-demo
spec:
  selector:
    app: orders-api
  ports:
  - port: 8080
    targetPort: 8080
    name: metrics
EOF

# ── Q6 prereq: slow-boot Deployment in probes-lab (no probes) ───────────────
kubectl apply -f - >/dev/null <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: slow-boot-script
  namespace: probes-lab
data:
  server.py: |
    import http.server, socketserver, time
    START = time.time()
    class H(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            elapsed = time.time() - START
            if self.path == '/healthz/started':
                code = 200 if elapsed >= 60 else 503
            elif self.path == '/healthz/ready':
                phase = int(elapsed) % 120
                code = 503 if 60 <= phase < 65 else 200
            elif self.path == '/healthz/live':
                code = 200
            else:
                code = 200
            self.send_response(code)
            self.end_headers()
        def log_message(self, *a): pass
    with socketserver.TCPServer(('', 8080), H) as s:
        s.serve_forever()
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: slow-boot
  namespace: probes-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: slow-boot
  template:
    metadata:
      labels:
        app: slow-boot
    spec:
      containers:
      - name: app
        image: python:3.11-slim
        command: ["python3", "/app/server.py"]
        ports:
        - containerPort: 8080
        volumeMounts:
        - name: script
          mountPath: /app
      volumes:
      - name: script
        configMap:
          name: slow-boot-script
EOF

# ── Q10 prereq: frontend/backend/db Deployments + Services in np-lab ─────────
kubectl apply -f - >/dev/null <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: np-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: app
        image: nginx:1.27
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: np-lab
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: np-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: app
        image: nginx:1.27
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: backend
  namespace: np-lab
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: db
  namespace: np-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: db
  template:
    metadata:
      labels:
        app: db
    spec:
      containers:
      - name: db
        image: postgres:16
        env:
        - name: POSTGRES_PASSWORD
          value: "exam"
        ports:
        - containerPort: 5432
---
apiVersion: v1
kind: Service
metadata:
  name: db
  namespace: np-lab
spec:
  selector:
    app: db
  ports:
  - port: 5432
    targetPort: 5432
EOF

echo "Exam environment ready."
