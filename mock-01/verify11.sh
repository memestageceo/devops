#!/bin/bash
# Q11: Deployment web-with-logger in sidecar-lab has initContainer with restartPolicy=Always
#      and a shared emptyDir volume

kubectl get deployment web-with-logger -n sidecar-lab &>/dev/null || \
  { echo "FAIL: Deployment 'web-with-logger' not found in sidecar-lab"; exit 1; }

RESTART=$(kubectl get deployment web-with-logger -n sidecar-lab \
  -o jsonpath='{.spec.template.spec.initContainers[0].restartPolicy}' 2>/dev/null)
[ "$RESTART" = "Always" ] || \
  { echo "FAIL: initContainer[0].restartPolicy=${RESTART} (expected Always for native sidecar)"; exit 1; }

# Check nginx is the main container
MAIN_IMAGE=$(kubectl get deployment web-with-logger -n sidecar-lab \
  -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
echo "$MAIN_IMAGE" | grep -q "nginx" || \
  { echo "FAIL: main container image '${MAIN_IMAGE}' does not look like nginx"; exit 1; }

# Check shared emptyDir volume exists
EMPTY_DIR=$(kubectl get deployment web-with-logger -n sidecar-lab -o json 2>/dev/null \
  | python3 -c "import sys,json; d=json.load(sys.stdin); \
    vols=d['spec']['template']['spec'].get('volumes',[]); \
    print(any(v.get('emptyDir') is not None for v in vols))" 2>/dev/null)
[ "$EMPTY_DIR" = "True" ] || \
  { echo "FAIL: no emptyDir volume found in web-with-logger pod spec"; exit 1; }

echo "PASS"
exit 0
