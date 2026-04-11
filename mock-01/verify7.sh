#!/bin/bash
# Q7: Pod audit-agent in proj-vol is Running and all four projected paths exist

kubectl get pod audit-agent -n proj-vol &>/dev/null || \
  { echo "FAIL: Pod 'audit-agent' not found in proj-vol"; exit 1; }

PHASE=$(kubectl get pod audit-agent -n proj-vol -o jsonpath='{.status.phase}' 2>/dev/null)
[ "$PHASE" = "Running" ] || { echo "FAIL: Pod audit-agent phase=${PHASE} (expected Running)"; exit 1; }

check_path() {
  kubectl exec audit-agent -n proj-vol -- ls "$1" &>/dev/null || \
    { echo "FAIL: $1 not found inside audit-agent"; exit 1; }
}

check_path /etc/agent/config/agent.yaml
check_path /etc/agent/secrets/username
check_path /etc/agent/secrets/password
check_path /etc/agent/token
check_path /etc/agent/meta/labels

echo "PASS"
exit 0
