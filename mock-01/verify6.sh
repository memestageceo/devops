#!/bin/bash
# Q6: slow-boot in probes-lab has startupProbe, readinessProbe, livenessProbe
#     startupProbe window (failureThreshold * periodSeconds) >= 120s

kubectl get deployment slow-boot -n probes-lab &>/dev/null || \
  { echo "FAIL: Deployment 'slow-boot' not found in probes-lab"; exit 1; }

STARTUP=$(kubectl get deployment slow-boot -n probes-lab \
  -o jsonpath='{.spec.template.spec.containers[0].startupProbe}' 2>/dev/null)
[ -n "$STARTUP" ] || { echo "FAIL: startupProbe not configured on slow-boot"; exit 1; }

READINESS=$(kubectl get deployment slow-boot -n probes-lab \
  -o jsonpath='{.spec.template.spec.containers[0].readinessProbe}' 2>/dev/null)
[ -n "$READINESS" ] || { echo "FAIL: readinessProbe not configured on slow-boot"; exit 1; }

LIVENESS=$(kubectl get deployment slow-boot -n probes-lab \
  -o jsonpath='{.spec.template.spec.containers[0].livenessProbe}' 2>/dev/null)
[ -n "$LIVENESS" ] || { echo "FAIL: livenessProbe not configured on slow-boot"; exit 1; }

# Verify startup window covers at least 120 seconds
FT=$(kubectl get deployment slow-boot -n probes-lab \
  -o jsonpath='{.spec.template.spec.containers[0].startupProbe.failureThreshold}' 2>/dev/null)
PS=$(kubectl get deployment slow-boot -n probes-lab \
  -o jsonpath='{.spec.template.spec.containers[0].startupProbe.periodSeconds}' 2>/dev/null)

FT=${FT:-0}
PS=${PS:-10}
WINDOW=$((FT * PS))
if [ "$WINDOW" -lt 120 ]; then
  echo "FAIL: startupProbe window = failureThreshold(${FT}) × periodSeconds(${PS}) = ${WINDOW}s (must be ≥ 120s)"
  exit 1
fi

echo "PASS (startup window = ${WINDOW}s)"
exit 0
