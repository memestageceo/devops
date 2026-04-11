#!/bin/bash
# Q1: Gateway API CRDs + GatewayClass nginx + Gateway web-gateway Programmed=True

kubectl get crd gateways.gateway.networking.k8s.io &>/dev/null || { echo "FAIL: Gateway API CRDs not installed"; exit 1; }
kubectl get crd httproutes.gateway.networking.k8s.io &>/dev/null || { echo "FAIL: HTTPRoute CRD not installed"; exit 1; }
kubectl get gatewayclass nginx &>/dev/null || { echo "FAIL: GatewayClass 'nginx' not found"; exit 1; }
kubectl get gateway web-gateway -n gw-demo &>/dev/null || { echo "FAIL: Gateway 'web-gateway' not found in gw-demo"; exit 1; }

STATUS=$(kubectl get gateway web-gateway -n gw-demo \
  -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}' 2>/dev/null)
if [ "$STATUS" != "True" ]; then
  echo "FAIL: Gateway web-gateway Programmed=${STATUS:-unknown} (expected True)"
  exit 1
fi

echo "PASS"
exit 0
