#!/bin/bash
# Q12: Worker node (node01) is Ready

STATUS=$(kubectl get node node01 \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)

if [ "$STATUS" = "True" ]; then
  echo "PASS: node01 is Ready"
  exit 0
else
  echo "FAIL: node01 Ready=${STATUS:-unknown} (expected True)"
  exit 1
fi
