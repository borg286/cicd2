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
