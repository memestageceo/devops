# Step 3 — Verify the custom content is served

Use `kubectl exec` to run `curl` inside the Pod and confirm nginx is serving the HTML from the ConfigMap:

```bash
kubectl exec nginx -- curl -s http://localhost
```{{exec}}

You should see the HTML you defined in the ConfigMap:

```
<!DOCTYPE html>
<html>
<body>
  <h1>Hello from ConfigMap!</h1>
</body>
</html>
```

## Bonus — update the content without restarting the Pod

Edit the ConfigMap to change the page title:

```bash
kubectl patch configmap nginx-html --type merge -p \
  '{"data":{"index.html":"<!DOCTYPE html>\n<html>\n<body>\n  <h1>Updated by patch!</h1>\n</body>\n</html>\n"}}'
```{{exec}}

Wait a few seconds for the mounted volume to sync, then curl again:

```bash
sleep 10 && kubectl exec nginx -- curl -s http://localhost
```{{exec}}

<details><summary>Solution</summary>

```bash
kubectl exec nginx -- curl -s http://localhost
```{{exec}}

</details>
