# Step 2 — Create an nginx Pod with the ConfigMap mounted as a volume

Now create a Pod that mounts the `nginx-html` ConfigMap at `/usr/share/nginx/html` — the default web root for nginx.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
    - name: nginx
      image: nginx:alpine
      ports:
        - containerPort: 80
      volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html
  volumes:
    - name: html
      configMap:
        name: nginx-html
```{{copy}}

Apply the manifest:

```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
    - name: nginx
      image: nginx:alpine
      ports:
        - containerPort: 80
      volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html
  volumes:
    - name: html
      configMap:
        name: nginx-html
EOF
```{{exec}}

Wait for the Pod to be ready:

```bash
kubectl wait pod nginx --for=condition=Ready --timeout=60s
```{{exec}}

<details><summary>Solution</summary>

```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
    - name: nginx
      image: nginx:alpine
      ports:
        - containerPort: 80
      volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html
  volumes:
    - name: html
      configMap:
        name: nginx-html
EOF
kubectl wait pod nginx --for=condition=Ready --timeout=60s
```{{exec}}

</details>
