#!/bin/bash
# Q15: controlplane has taint workload=critical:NoSchedule, both nodes have zone label,
#      Deployment critical-app in sched-lab has topologySpreadConstraints with maxSkew=1

TAINT=$(kubectl get node controlplane \
  -o jsonpath='{.spec.taints[?(@.key=="workload")].effect}' 2>/dev/null)
[ "$TAINT" = "NoSchedule" ] || \
  { echo "FAIL: controlplane taint workload=critical:NoSchedule not found (got: ${TAINT:-none})"; exit 1; }

ZONE_CP=$(kubectl get node controlplane -o jsonpath='{.metadata.labels.zone}' 2>/dev/null)
[ -n "$ZONE_CP" ] || { echo "FAIL: controlplane missing 'zone' label"; exit 1; }

ZONE_W=$(kubectl get node node01 -o jsonpath='{.metadata.labels.zone}' 2>/dev/null)
[ -n "$ZONE_W" ] || { echo "FAIL: node01 missing 'zone' label"; exit 1; }

[ "$ZONE_CP" != "$ZONE_W" ] || \
  { echo "FAIL: both nodes have the same zone label '${ZONE_CP}' (they should differ)"; exit 1; }

kubectl get deployment critical-app -n sched-lab &>/dev/null || \
  { echo "FAIL: Deployment 'critical-app' not found in sched-lab"; exit 1; }

REPLICAS=$(kubectl get deployment critical-app -n sched-lab \
  -o jsonpath='{.spec.replicas}' 2>/dev/null)
[ "$REPLICAS" = "4" ] || { echo "FAIL: critical-app replicas=${REPLICAS} (expected 4)"; exit 1; }

MAX_SKEW=$(kubectl get deployment critical-app -n sched-lab -o json 2>/dev/null \
  | python3 -c "import sys,json; d=json.load(sys.stdin); \
    tsc=d['spec']['template']['spec'].get('topologySpreadConstraints',[]); \
    print(tsc[0].get('maxSkew','') if tsc else '')" 2>/dev/null)
[ "$MAX_SKEW" = "1" ] || \
  { echo "FAIL: topologySpreadConstraints[0].maxSkew=${MAX_SKEW} (expected 1)"; exit 1; }

# Check topology key is zone
TOPO_KEY=$(kubectl get deployment critical-app -n sched-lab -o json 2>/dev/null \
  | python3 -c "import sys,json; d=json.load(sys.stdin); \
    tsc=d['spec']['template']['spec'].get('topologySpreadConstraints',[]); \
    print(tsc[0].get('topologyKey','') if tsc else '')" 2>/dev/null)
[ "$TOPO_KEY" = "zone" ] || \
  { echo "FAIL: topologySpreadConstraints topologyKey=${TOPO_KEY} (expected zone)"; exit 1; }

echo "PASS (controlplane zone=${ZONE_CP}, node01 zone=${ZONE_W}, maxSkew=1)"
exit 0
