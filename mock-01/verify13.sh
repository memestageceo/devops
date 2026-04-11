#!/bin/bash
# Q13: All nodes report the same kubelet version and all kube-system pods are Running/Completed

VERSIONS=$(kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.kubeletVersion}' 2>/dev/null)
UNIQUE=$(echo "$VERSIONS" | tr ' ' '\n' | sort -u | wc -l)

if [ "$UNIQUE" -ne 1 ]; then
  echo "FAIL: nodes report different versions: $VERSIONS"
  exit 1
fi

NOT_OK=$(kubectl get pods -n kube-system --no-headers 2>/dev/null \
  | grep -v -E "Running|Completed" | wc -l)
if [ "$NOT_OK" -gt 0 ]; then
  echo "FAIL: $NOT_OK kube-system pod(s) are not Running/Completed:"
  kubectl get pods -n kube-system --no-headers | grep -v -E "Running|Completed"
  exit 1
fi

VERSION=$(echo "$VERSIONS" | tr ' ' '\n' | sort -u)
echo "PASS: all nodes at $VERSION, all kube-system pods healthy"
exit 0
