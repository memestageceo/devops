#!/bin/bash
# Q4: kubelet on node01 has maxPods=80, evictionHard memory.available=200Mi, systemReserved cpu=200m

CONFIGZ=$(kubectl get --raw "/api/v1/nodes/node01/proxy/configz" 2>/dev/null) || \
  { echo "FAIL: cannot reach node01 configz (is node01 Ready?)"; exit 1; }

MAX_PODS=$(echo "$CONFIGZ" | python3 -c "import sys,json; print(json.load(sys.stdin)['kubeletconfig'].get('maxPods',''))" 2>/dev/null)
[ "$MAX_PODS" = "80" ] || { echo "FAIL: maxPods=${MAX_PODS} (expected 80)"; exit 1; }

EVICTION=$(echo "$CONFIGZ" | python3 -c "import sys,json; print(json.load(sys.stdin)['kubeletconfig'].get('evictionHard',{}).get('memory.available',''))" 2>/dev/null)
[ "$EVICTION" = "200Mi" ] || { echo "FAIL: evictionHard.memory.available=${EVICTION} (expected 200Mi)"; exit 1; }

SYS_CPU=$(echo "$CONFIGZ" | python3 -c "import sys,json; print(json.load(sys.stdin)['kubeletconfig'].get('systemReserved',{}).get('cpu',''))" 2>/dev/null)
[ "$SYS_CPU" = "200m" ] || { echo "FAIL: systemReserved.cpu=${SYS_CPU} (expected 200m)"; exit 1; }

echo "PASS"
exit 0
