#!/bin/bash
set -euo pipefail


if ! command -v oc >/dev/null 2>&1; then
  echo "Error: oc CLI is not installed. Please install OpenShift CLI (oc) and try again."
  exit 1
fi
if ! command -v sed >/dev/null 2>&1; then
  echo "Error: sed is not available. Please install sed and try again."
  exit 1
fi


echo "Verifying OpenShift login..."
if ! oc whoami &>/dev/null; then
  echo "It appears you are not logged in. Please login using 'oc login' and then re-run this script."
  exit 1
fi
echo "Login verified: $(oc whoami)"


read -rp "Enter the Argo CD application source Git repo URL: " REPO_URL
sed -i.bak -E "s|(repoURL:[[:space:]]+)[^[:space:]]+|\1${REPO_URL}|" ./applications/cloud-pak-deployer.yaml
rm -f ./applications/cloud-pak-deployer.yaml.bak
echo "Updated applications/cloud-pak-deployer.yaml with repoURL: $REPO_URL"

read -rp "Would you like to commit and push this change now? (y/n): " PUSH_NOW
if [[ "$PUSH_NOW" =~ ^[Yy]$ ]]; then
  git add .
  if git diff --cached --quiet; then
    echo "No changes to commit. Your repository is up-to-date."
  else
    git commit -m "Update configuration for Argo CD application"
    git push
  fi
fi


read -srp "Enter the IBM Container Entitlement Key (from https://myibm.ibm.com/products-services/containerlibrary): " ENTITLEMENT_KEY
echo ""


echo "Updating the cloud-pak-entitlement-key secret..."
if oc get secret cloud-pak-entitlement-key -n cloud-pak-deployer &>/dev/null; then
  oc delete secret cloud-pak-entitlement-key -n cloud-pak-deployer
fi
oc create secret generic cloud-pak-entitlement-key \
  --namespace=cloud-pak-deployer \
  --from-literal=cp-entitlement-key="${ENTITLEMENT_KEY}"
echo "Secret updated successfully."


echo "Applying the Argo CD Application manifest..."
oc apply -f ./applications/cloud-pak-deployer.yaml -n openshift-gitops
echo "Argo CD Application bootstrapped successfully."


echo "Retrieving Argo CD dashboard information..."
ARGO_ROUTE=$(oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}')
ARGO_PASS=$(oc get secret argocd-secret -n openshift-gitops -o jsonpath="{.data.admin\.password}" | base64 -d)
if [ -z "${ARGO_ROUTE}" ] || [ -z "${ARGO_PASS}" ]; then
  echo "Error: Could not retrieve Argo CD dashboard URL or admin password. Please check your Argo CD installation."
  exit 1
fi


echo "===================================================================="
echo "Argo CD Dashboard URL : https://${ARGO_ROUTE}"
echo "Argo CD Admin Password: ${ARGO_PASS}"
echo "===================================================================="
