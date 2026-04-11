#!/bin/bash
# Q5: HPA orders-hpa exists in metrics-demo, targets orders-api, min=2 max=10

kubectl get hpa orders-hpa -n metrics-demo &>/dev/null || \
  { echo "FAIL: HPA 'orders-hpa' not found in metrics-demo"; exit 1; }

TARGET=$(kubectl get hpa orders-hpa -n metrics-demo \
  -o jsonpath='{.spec.scaleTargetRef.name}' 2>/dev/null)
[ "$TARGET" = "orders-api" ] || { echo "FAIL: scaleTargetRef.name=${TARGET} (expected orders-api)"; exit 1; }

MIN=$(kubectl get hpa orders-hpa -n metrics-demo -o jsonpath='{.spec.minReplicas}' 2>/dev/null)
[ "$MIN" = "2" ] || { echo "FAIL: minReplicas=${MIN} (expected 2)"; exit 1; }

MAX=$(kubectl get hpa orders-hpa -n metrics-demo -o jsonpath='{.spec.maxReplicas}' 2>/dev/null)
[ "$MAX" = "10" ] || { echo "FAIL: maxReplicas=${MAX} (expected 10)"; exit 1; }

# Check the metric name contains orders_in_flight
METRIC=$(kubectl get hpa orders-hpa -n metrics-demo -o json \
  | python3 -c "import sys,json; h=json.load(sys.stdin); \
    names=[m.get('pods',{}).get('metric',{}).get('name','') \
           for m in h['spec'].get('metrics',[])] ; \
    print('orders_in_flight' in names)" 2>/dev/null)
[ "$METRIC" = "True" ] || { echo "FAIL: metric 'orders_in_flight' not found in HPA spec"; exit 1; }

echo "PASS"
exit 0
