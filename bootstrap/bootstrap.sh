#!/bin/bash

set -e

# Function to generate random password
generate_password() {
  cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1
}

# Create namespaces if they don't exist
kubectl create namespace forgejo --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace flux-system --dry-run=client -o yaml | kubectl apply -f -

# Generate passwords
FORGEJO_ADMIN_PASS=$(generate_password)
GITEA_FLUX_PASS=$(generate_password)

kubectl create secret generic forgejo-admin \
  --namespace forgejo \
  --from-literal=username=gitea_admin \
  --from-literal=password="$FORGEJO_ADMIN_PASS" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic gitea-admin \
  --namespace flux-system \
  --from-literal=username=gitea_admin \
  --from-literal=password="$FORGEJO_ADMIN_PASS" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic gitea-flux-password \
  --namespace flux-system \
  --from-literal=flux_user_password="$GITEA_FLUX_PASS" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic gitea-flux-password \
  --namespace forgejo \
  --from-literal=flux_user_password="$GITEA_FLUX_PASS" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Secrets created successfully."
echo "Forgejo/Gitea Admin Password: $FORGEJO_ADMIN_PASS"
echo "Gitea Flux Password: $GITEA_FLUX_PASS"
echo "Please save these credentials securely."

# Apply Flux and components
kubectl apply -f https://github.com/fluxcd/flux2/releases/latest/download/install.yaml

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -f "$SCRIPT_DIR/gotk-sync.yaml" ]; then
  echo "Applying local gotk-sync.yaml..."
  kubectl apply -f "$SCRIPT_DIR/gotk-sync.yaml"
else
  kubectl apply -f https://raw.githubusercontent.com/borg286/cicd2/refs/heads/main/bootstrap/gotk-sync.yaml
fi

if [ -f "$SCRIPT_DIR/tf-controller-install.yaml" ]; then
  echo "Applying local tf-controller-install.yaml..."
  kubectl apply -f "$SCRIPT_DIR/tf-controller-install.yaml"
else
  kubectl apply -f https://raw.githubusercontent.com/borg286/cicd2/refs/heads/main/bootstrap/tf-controller-install.yaml
fi
