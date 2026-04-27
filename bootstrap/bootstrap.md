# Bootstrapping - Gitea & Flux GitOps Setup

This document summarizes the architecture, bootstrapping procedure, validation techniques, and key lessons learned during the setup of the GitOps pipeline using Flux and the Tofu Controller. It is intended to guide future modifications and prevent reinventing solutions to encountered issues.

## 1. Architecture
The setup implements a complete GitOps pipeline combining Infrastructure as Code (IaC) and continuous delivery:

*   **Flux (v2):** The main engine for GitOps, pulling configurations from a public GitHub repository (`https://github.com/borg286/cicd2.git`).
*   **Tofu Controller (contrib/fork):** Managed by Flux, it executes OpenTofu (Terraform) code to handle resource creation within the cluster application layer.
*   **Forgejo (Gitea compatible):** The Git server deployed via Flux, intended to host the repositories that Flux manages or pulls from in the future (currently pulling from GitHub).

## 2. Bootstrapping Procedure
To recreate or understand the setup, follow this procedure:

*   **Manual Secrets:** Run the `bootstrap.sh` script in the `bootstrap` folder to create the necessary secrets in the cluster as prerequisites (never commit these to Git):
    *   `forgejo-admin` (in `forgejo` namespace): Initial admin credentials.
    *   `gitea-admin` (in `flux-system` namespace): Credentials for Tofu Controller to authenticate with Forgejo via Basic Auth.
    *   `gitea-flux-password` (in `flux-system` namespace): Password for the Flux user to be created in Gitea.
    *   `forgejo-admin-token` (in `forgejo` namespace): Token with `write:admin` scope for JIT registration of runners. This must be created manually in the Forgejo UI after it is running and saved to the cluster using `kubectl`.
*   **Flux Installation:** Use `flux bootstrap` (requires GitHub PAT with write access) or the "Dev install" path (`kubectl apply -f https://github.com/fluxcd/flux2/releases/latest/download/install.yaml` for read-only on public repos).
*   **Manifest Application:** Apply the `gotk-sync.yaml` manifest found in the `bootstrap` folder to point Flux to the GitHub repo and start reconciliation.
    *   Command: `kubectl apply -f bootstrap/gotk-sync.yaml`
*   **Cycle Breaking:** If Flux gets stuck on dry-run validation because a resource uses a CRD that is not yet installed by an operator in the same batch, manually apply the manifests in the `flux-system` folder using `kubectl apply -k` to unblock the loop.

## 3. Validation Techniques
To verify the state and debug issues:

*   **Pod Status:** Use `kubectl get pods -A` or `:pods` in k9s to check if controllers and applications are running and ready.
*   **Flux Status:** Use `flux get kustomizations` and `flux get helmreleases -A` to check if syncs are successful.
*   **Logs:** Check logs of specific failing pods (e.g., `kubectl logs -n flux-system tofu-controller-...`) to find detailed error messages, especially from Terraform runners.
*   **Custom Resources:** Check the status of the Terraform resource using `kubectl get terraforms.infra.contrib.fluxcd.io -A`.

## 4. Dependencies
*   **CRD Ordering:** You cannot apply a custom resource (like Terraform or HelmRelease) in the same Kustomization batch as the resource that installs its CustomResourceDefinition (CRD) unless the dry-run is skipped or strictly ordered.
*   **Separation:** We separated the file `gitea-terraform.yaml` to an `apps/` directory and used a distinct Flux Kustomization with `dependsOn` to ensure the controller was installed first.

## 5. Tools Required
An AI or human operator making future modifications should be familiar with:

*   **kubectl:** Essential for all Kubernetes operations, debugging, and recovery.