#!/bin/bash
# Q2: HTTPRoute app-route in gw-demo with 80/20 split and canary header rule

kubectl get httproute app-route -n gw-demo &>/dev/null || { echo "FAIL: HTTPRoute 'app-route' not found in gw-demo"; exit 1; }

# Check both services are referenced as backends
V1=$(kubectl get httproute app-route -n gw-demo -o json \
  | python3 -c "import sys,json; r=json.load(sys.stdin); \
    refs=[b['name'] for rule in r['spec']['rules'] for b in rule.get('backendRefs',[])] ; \
    print('app-v1-svc' in refs)" 2>/dev/null)
V2=$(kubectl get httproute app-route -n gw-demo -o json \
  | python3 -c "import sys,json; r=json.load(sys.stdin); \
    refs=[b['name'] for rule in r['spec']['rules'] for b in rule.get('backendRefs',[])] ; \
    print('app-v2-svc' in refs)" 2>/dev/null)

[ "$V1" = "True" ] || { echo "FAIL: app-v1-svc not found as a backendRef"; exit 1; }
[ "$V2" = "True" ] || { echo "FAIL: app-v2-svc not found as a backendRef"; exit 1; }

# Check weights 80 and 20 exist
W80=$(kubectl get httproute app-route -n gw-demo -o json \
  | python3 -c "import sys,json; r=json.load(sys.stdin); \
    weights=[b.get('weight') for rule in r['spec']['rules'] for b in rule.get('backendRefs',[])] ; \
    print(80 in weights)" 2>/dev/null)
W20=$(kubectl get httproute app-route -n gw-demo -o json \
  | python3 -c "import sys,json; r=json.load(sys.stdin); \
    weights=[b.get('weight') for rule in r['spec']['rules'] for b in rule.get('backendRefs',[])] ; \
    print(20 in weights)" 2>/dev/null)

[ "$W80" = "True" ] || { echo "FAIL: weight 80 not found in backendRefs"; exit 1; }
[ "$W20" = "True" ] || { echo "FAIL: weight 20 not found in backendRefs"; exit 1; }

# Check header match x-canary: true exists
CANARY=$(kubectl get httproute app-route -n gw-demo -o json \
  | python3 -c "import sys,json; r=json.load(sys.stdin); \
    found=any(h.get('name')=='x-canary' and h.get('value')=='true' \
      for rule in r['spec']['rules'] \
      for m in rule.get('matches',[]) \
      for h in m.get('headers',[])) ; \
    print(found)" 2>/dev/null)
[ "$CANARY" = "True" ] || { echo "FAIL: header match 'x-canary: true' not found"; exit 1; }

echo "PASS"
exit 0
