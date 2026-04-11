#!/bin/bash
# Q3: Cilium DaemonSet running, both nodes Ready, Hubble enabled

kubectl get daemonset cilium -n kube-system &>/dev/null || { echo "FAIL: cilium DaemonSet not found in kube-system"; exit 1; }

DESIRED=$(kubectl get daemonset cilium -n kube-system -o jsonpath='{.status.desiredNumberScheduled}')
READY=$(kubectl get daemonset cilium -n kube-system -o jsonpath='{.status.numberReady}')
[ "$READY" -ge "$DESIRED" ] || { echo "FAIL: cilium DaemonSet not fully ready ($READY/$DESIRED)"; exit 1; }

NOT_READY=$(kubectl get nodes --no-headers | grep -c "NotReady" || true)
[ "$NOT_READY" -eq 0 ] || { echo "FAIL: $NOT_READY node(s) are NotReady"; exit 1; }

# Check Hubble is enabled (either hubble-peer DS or cilium-config CM)
HUBBLE=$(kubectl get configmap cilium-config -n kube-system \
  -o jsonpath='{.data.enable-hubble}' 2>/dev/null)
if [ "$HUBBLE" != "true" ]; then
  kubectl get daemonset hubble-peer -n kube-system &>/dev/null || \
    { echo "FAIL: Hubble does not appear to be enabled (enable-hubble != true in cilium-config)"; exit 1; }
fi

echo "PASS"
exit 0
