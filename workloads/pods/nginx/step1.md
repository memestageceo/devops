# Step 1 — Create a ConfigMap with custom HTML

A **ConfigMap** lets you store non-confidential key/value data. When mounted as a volume, each key becomes a file inside the container.

Create a ConfigMap named `nginx-html` with a single key `index.html`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-html
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <body>
      <h1>Hello from ConfigMap!</h1>
    </body>
    </html>
```{{copy}}

Apply it:

```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-html
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <body>
      <h1>Hello from ConfigMap!</h1>
    </body>
    </html>
EOF
```{{exec}}

Confirm the ConfigMap was created:

```bash
kubectl get configmap nginx-html
```{{exec}}

<details><summary>Solution</summary>

```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-html
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <body>
      <h1>Hello from ConfigMap!</h1>
    </body>
    </html>
EOF
```{{exec}}

</details>
