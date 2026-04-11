#!/bin/bash
# Q14: ServiceAccount deploy-bot, Role with correct rules, RoleBinding in rbac-lab

kubectl get serviceaccount deploy-bot -n rbac-lab &>/dev/null || \
  { echo "FAIL: ServiceAccount 'deploy-bot' not found in rbac-lab"; exit 1; }

# Check at least one Role exists in rbac-lab
ROLE_COUNT=$(kubectl get role -n rbac-lab --no-headers 2>/dev/null | wc -l)
[ "$ROLE_COUNT" -ge 1 ] || { echo "FAIL: no Role found in rbac-lab"; exit 1; }

# Check a RoleBinding exists that links deploy-bot SA
RB=$(kubectl get rolebinding -n rbac-lab -o json 2>/dev/null | python3 - <<'PYEOF'
import sys, json
data = json.load(sys.stdin)
for item in data.get("items", []):
    for sub in item.get("spec", {}).get("subjects", []):
        if sub.get("name") == "deploy-bot" and sub.get("kind") == "ServiceAccount":
            print("found")
            sys.exit(0)
PYEOF
)
[ "$RB" = "found" ] || \
  { echo "FAIL: no RoleBinding found linking ServiceAccount 'deploy-bot' to a Role"; exit 1; }

# Verify deploy-bot can list deployments in rbac-lab
CAN=$(kubectl auth can-i list deployments \
  --as=system:serviceaccount:rbac-lab:deploy-bot -n rbac-lab 2>/dev/null)
[ "$CAN" = "yes" ] || { echo "FAIL: deploy-bot cannot list deployments in rbac-lab"; exit 1; }

# Verify deploy-bot cannot delete deployments
CANNOT=$(kubectl auth can-i delete deployments \
  --as=system:serviceaccount:rbac-lab:deploy-bot -n rbac-lab 2>/dev/null)
[ "$CANNOT" = "no" ] || { echo "FAIL: deploy-bot can delete deployments (should be denied)"; exit 1; }

echo "PASS"
exit 0
