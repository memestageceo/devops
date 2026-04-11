#!/bin/bash
# Q10: default-deny (empty podSelector, both Ingress+Egress) + ≥3 selective-allow policies in np-lab

POLICY_COUNT=$(kubectl get networkpolicy -n np-lab --no-headers 2>/dev/null | wc -l)
[ "$POLICY_COUNT" -ge 4 ] || \
  { echo "FAIL: only ${POLICY_COUNT} NetworkPolicies in np-lab (expected ≥4)"; exit 1; }

# Check that a default-deny policy exists: empty podSelector + both policyTypes
DEFAULT_DENY=$(kubectl get networkpolicy -n np-lab -o json 2>/dev/null | python3 - <<'PYEOF'
import sys, json
data = json.load(sys.stdin)
for item in data.get("items", []):
    spec = item.get("spec", {})
    sel = spec.get("podSelector", {})
    pt = spec.get("policyTypes", [])
    if sel in ({}, {"matchLabels": {}}, {"matchExpressions": []}) \
       and "Ingress" in pt and "Egress" in pt:
        print("found")
        break
PYEOF
)
[ "$DEFAULT_DENY" = "found" ] || \
  { echo "FAIL: no default-deny policy found (need empty podSelector with both Ingress and Egress)"; exit 1; }

echo "PASS (${POLICY_COUNT} policies found, default-deny confirmed)"
exit 0
