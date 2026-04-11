#!/bin/bash
# Q9: PV app1-pv Bound, PVC app1-pvc Bound, Deployment writer has ≥1 ready replica

kubectl get pv app1-pv &>/dev/null || { echo "FAIL: PersistentVolume 'app1-pv' not found"; exit 1; }
PV_STATUS=$(kubectl get pv app1-pv -o jsonpath='{.status.phase}' 2>/dev/null)
[ "$PV_STATUS" = "Bound" ] || { echo "FAIL: PV app1-pv phase=${PV_STATUS} (expected Bound)"; exit 1; }

kubectl get pvc app1-pvc -n storage-lab &>/dev/null || \
  { echo "FAIL: PVC 'app1-pvc' not found in storage-lab"; exit 1; }
PVC_STATUS=$(kubectl get pvc app1-pvc -n storage-lab -o jsonpath='{.status.phase}' 2>/dev/null)
[ "$PVC_STATUS" = "Bound" ] || { echo "FAIL: PVC app1-pvc phase=${PVC_STATUS} (expected Bound)"; exit 1; }

kubectl get deployment writer -n storage-lab &>/dev/null || \
  { echo "FAIL: Deployment 'writer' not found in storage-lab"; exit 1; }
READY=$(kubectl get deployment writer -n storage-lab \
  -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
[ "${READY:-0}" -ge 1 ] || { echo "FAIL: Deployment writer has no ready replicas"; exit 1; }

echo "PASS"
exit 0
