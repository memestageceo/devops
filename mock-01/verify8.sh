#!/bin/bash
# Q8: Snapshot exists in /opt/backups/, cluster healthy, will-be-lost namespace gone

ls /opt/backups/etcd-snap-*.db &>/dev/null || \
  { echo "FAIL: No snapshot found under /opt/backups/etcd-snap-*.db"; exit 1; }

kubectl get nodes &>/dev/null || { echo "FAIL: kubectl cannot reach the cluster"; exit 1; }

NOT_READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -c "NotReady" || true)
[ "$NOT_READY" -eq 0 ] || { echo "FAIL: $NOT_READY node(s) are NotReady after restore"; exit 1; }

if kubectl get namespace will-be-lost &>/dev/null; then
  echo "FAIL: namespace 'will-be-lost' still exists (restore did not take effect)"
  exit 1
fi

echo "PASS"
exit 0
