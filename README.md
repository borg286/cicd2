# CI/CD Pipeline for Gitea and Tofu Controller

This repository contains the configuration for a GitOps pipeline using Flux CD and Tofu Controller (OpenTofu) to manage Gitea/Forgejo resources.

## Architecture

The repository is organized into two main areas to support clean bootstrapping and ongoing GitOps management:

### 1. Bootstrap Folder (`bootstrap/`)
- Contains files needed to initialize the cluster before Flux is fully operational.
- **`bootstrap.sh`**: An imperative script that creates initial namespaces, generates random passwords, creates Kubernetes secrets, and installs Flux CD.
- **`tf-controller-install.yaml`**: The manifest to install Tofu Controller. This file is kept here to serve as documentation for the required bootstrapping components and can be applied manually if needed.

### 2. Cluster Folder (`clusters/my-cluster/`)
- Contains the state of the cluster managed by Flux.
- **`flux-system/kustomization.yaml`**: The main Kustomization file for cluster resources.
- To avoid duplication, this file references `tf-controller-install.yaml` in the `bootstrap` folder using a relative path: `../../../bootstrap/tf-controller-install.yaml`.

This setup ensures that Tofu Controller is applied during bootstrapping and continues to be managed by Flux afterward, without duplicating the manifest file.

## Bootstrapping Instructions

To bootstrap a new cluster, follow these steps:

### `bootstrap.sh` Content

```bash
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
  --from-literal=flux_user_password="$GITEA_FLUX_PASS" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Secrets created successfully."
echo "Forgejo Admin Password: $FORGEJO_ADMIN_PASS"
echo "Gitea Admin Password: $GITEA_ADMIN_PASS"
echo "Gitea Flux Password: $GITEA_FLUX_PASS"
echo "Please save these credentials securely."

kubectl apply -f https://github.com/fluxcd/flux2/releases/latest/download/install.yaml
kubectl apply -f gotk-sync.yaml
```

1.  **Set up Secrets**: The `bootstrap.sh` script handles this automatically by generating random passwords and creating the necessary secrets in the `forgejo` and `flux-system` namespaces.

2.  **Run the Script**: Execute the script from the root of the repository (or the bootstrap folder):
    ```bash
    ./bootstrap/bootstrap.sh
    ```

    *Note: The script requires `kubectl` to be configured to point to your target cluster.*

3.  **Manual Fallback**: If you prefer to install components manually without the script:
    - Apply the Flux installation manifests directly from GitHub or via the Flux CLI.
    - Apply the Tofu Controller manifest from this repository:
      ```bash
      kubectl apply -f bootstrap/tf-controller-install.yaml
      ```
    - Create the required secrets (`gitea-admin`, `gitea-flux-password`) manually with appropriate keys.

## Future Modifications
To update the Tofu Controller version or configuration, modify the file in the `bootstrap/` folder and Flux will automatically reconcile the changes in the cluster.
