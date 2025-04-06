#!/bin/bash

set -e

NAMESPACE="cloud-pak-deployer"

echo "===== Cloud Pak for Data Secret Bootstrap Script ====="
echo

read -rp "Enter your 'oc login' command (you can copy from OpenShift Console): " OC_LOGIN_CMD
echo
echo "Running your oc login command..."
eval "$OC_LOGIN_CMD"

read -rsp "Enter your IBM Container Entitlement Key (from https://myibm.ibm.com/products-services/containerlibrary): " CPD_ENTITLEMENT_KEY
echo

echo "Creating namespace '$NAMESPACE' if not exists..."
oc get namespace "$NAMESPACE" >/dev/null 2>&1 || oc create namespace "$NAMESPACE"

echo "Creating 'cpd-entitlement' secret..."
oc delete secret cpd-entitlement -n "$NAMESPACE" --ignore-not-found
oc create secret generic cpd-entitlement \
  --from-literal=entitlement.key="$CPD_ENTITLEMENT_KEY" \
  -n "$NAMESPACE"

echo "Creating 'oc-login-secret' secret..."
oc delete secret oc-login-secret -n "$NAMESPACE" --ignore-not-found
oc create secret generic oc-login-secret \
  --from-literal=oc-login-cmd="$OC_LOGIN_CMD" \
  -n "$NAMESPACE"

echo
echo "Secrets created successfully in namespace '$NAMESPACE'"

