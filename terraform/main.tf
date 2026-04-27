terraform {
  required_providers {
    gitea = {
      source = "go-gitea/gitea"
    }
  }
}

provider "gitea" {
  base_url = "http://forgejo-http.forgejo:3000"
  username = var.username
  password = var.password
}

variable "username" {
  type      = string
}

variable "password" {
  type      = string
  sensitive = true
}

resource "gitea_token" "tofu_managed_token" {
  name   = "tofu-sync-token"
  scopes = ["all"]
}

resource "gitea_org" "my_org" {
  name = "my-org"
}

resource "gitea_repository" "mirror_repo" {
  name        = "cloned-repo"
  username    = gitea_org.my_org.name
  # Logic: Set mirror to false for a one-time clone/migration.
  # If you set mirror = true, Gitea locks the repo to read-only sync, 
  # which disables Actions and manual pushes.
  mirror                  = false 
  migration_service       = "git"
  migration_clone_address = "https://github.com/borg286/cicd2.git"

  # This prevents Terraform from seeing "drift" when Gitea clears 
  # the migration address after the initial successful clone.
  lifecycle {
    ignore_changes = [
      migration_service,
      migration_clone_address,
    ]
  }
}

variable "flux_user_password" {
  type      = string
  sensitive = true
}

resource "gitea_user" "flux_user" {
  username   = "flux-agent"
  login_name = "flux-agent"
  email      = "flux@example.com"
  password   = var.flux_user_password
}
