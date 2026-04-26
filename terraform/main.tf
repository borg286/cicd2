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
  mirror      = true
  migration_service       = "git"
  migration_clone_address = "https://github.com/borg286/cicd2.git"
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
