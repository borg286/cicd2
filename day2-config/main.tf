terraform {
  required_providers {
    gitea = {
      source  = "go-gitea/gitea"
      version = "0.6.0"
    }
    flux = {
      source = "fluxcd/flux"
    }
    kubernetes = { source = "hashicorp/kubernetes" }
    terracurl = {
      source = "devops-rob/terracurl"
    }
  }
}

variable "forgejo_password" {
  type        = string
  description = "The admin password for Forgejo"
  sensitive   = true
  # No default value means Terraform will prompt you if it's not provided
}

# Pointing to the Port-Forwarded address
provider "gitea" {
  base_url = "http://localhost:3000"
  username = "forgejo-admin"
  password = var.forgejo_password
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

# 1. Create Org and Repo
resource "gitea_org" "main_org" {
  name = "main-org"
}

resource "gitea_repository" "gitops_repo" {
  name     = "main-repo"
  username = gitea_org.main_org.name
  private  = false # Set to true if adding Flux credentials
  # Ensure no default files are created
  auto_init   = false
}


resource "kubernetes_manifest" "flux_source" {
  manifest = yamldecode(file("${path.module}/GitRepo.yaml"))
}

resource "kubernetes_manifest" "flux_kustomiazation" {
  manifest = yamldecode(file("${path.module}/GitKustomization.yaml"))
}
# 1. Admin-scoped token for the one-time system fetch
resource "gitea_token" "admin_provisioner" {
  name   = "temp-admin-provisioner"
  scopes = ["all"] 
}

# 2. Scoped token for your downstream "User-Resources" Terraform
resource "gitea_token" "user_manager" {
  name   = "user-management-token"
  # Note: Forgejo requires 'write:admin' or 'admin:all' to create users via API
  scopes = ["write:admin", "write:user", "write:organization"] 
}

# 3. Fetch the system-wide runner registration token
resource "terracurl_request" "runner_registration_token" {
  name   = "runner_registration_token"
  # Ensure DNS matches your internal service name
  url    = "http://localhost:3000/api/v1/admin/runners/registration-token"
  method = "GET"

  headers = {
    Authorization = "token ${gitea_token.admin_provisioner.token}"
  }

  response_codes = [200]
}

# 4. Secret for Gitea Runners (System-wide registration)
resource "kubernetes_secret_v1" "runner_token" {
  metadata {
    name      = "runner-token"
    namespace = "flux-system"
  }

  type = "Opaque"

  data = {
    # Properly decoding the JSON body from the Terracurl response
    RUNNER_REGISTRATION_TOKEN = jsondecode(terracurl_request.runner_registration_token.response).token
  }
}

# 5. Secret for the Tofu-Controller (User Provisioning)
resource "kubernetes_secret_v1" "forgejo_tf_auth" {
  metadata {
    name      = "forgejo-tf-auth"
    namespace = "flux-system"
  }

  type = "Opaque"

  data = {
    # Directly using the token attribute from the user_manager resource
    token = gitea_token.user_manager.token
    admin_username = "forgejo-admin"
    admin_password = var.forgejo_password
  }
}
