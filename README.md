Sovereign GitOps Bootstrap
This guide outlines the "Two-Step" bootstrap process to link a local k3d cluster with a self-hosted Forgejo instance and FluxCD.

Phase 1: Infrastructure
Navigate to day1-infra/.

Run terraform init && terraform apply.

This installs the Forgejo and Flux controllers. Wait for the pods to be Ready.

Phase 2: The Bridge (Manual)
Terraform cannot reach the internal Forgejo API from your host machine yet. You must create a tunnel:

Bash
# Open a new terminal and keep this running
kubectl port-forward -n forgejo svc/forgejo-http 3000:3000
Phase 3: Configuration & Seeding
Initialize the Repo: Navigate to your day2-config/ and run terraform init && terraform apply. This creates the infra-org/cluster-config repository.

Seed the Data:
Push your local files to the new Forgejo server:

Bash
cd ../bootstrap-repo
git init
git remote add origin http://localhost:3000/main-org/main-repo.git
git add .
git commit -m "initial bootstrap"
#The "Force" move: -f overwrites the remote 'main' branch regardless of history
git push -f -u origin main
Phase 4: Verification
Check Flux's status within the cluster:

Bash
flux get sources git
Flux will now pull from the internal address [http://forgejo-http.forgejo.svc.cluster.local:3000/](http://forgejo-http.forgejo.svc.cluster.local:3000/)... which bypasses the need for the port-forward for ongoing operations.
