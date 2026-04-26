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
GITEA_ADMIN_PASS=$(generate_password)
GITEA_FLUX_PASS=$(generate_password)

# Create secrets
kubectl create secret generic forgejo-admin \
  --namespace forgejo \
  --from-literal=username=admin \
  --from-literal=password="$FORGEJO_ADMIN_PASS" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic gitea-admin \
  --namespace flux-system \
  --from-literal=username=admin \
  --from-literal=password="$GITEA_ADMIN_PASS" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic gitea-flux-password \
  --namespace flux-system \
  --from-literal=username=flux \
  --from-literal=password="$GITEA_FLUX_PASS" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Secrets created successfully."
echo "Forgejo Admin Password: $FORGEJO_ADMIN_PASS"
echo "Gitea Admin Password: $GITEA_ADMIN_PASS"
echo "Gitea Flux Password: $GITEA_FLUX_PASS"
echo "Please save these credentials securely."
