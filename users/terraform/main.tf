terraform {
  required_providers {
    gitea = {
      source = "go-gitea/gitea"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
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

resource "gitea_team" "devs" {
  name         = "Devs"
  organisation = "my-org"
  description  = "Devs of my-org"
  permission   = "write"
}

variable "borg286_password" {
  type      = string
  sensitive = true
}

resource "gitea_user" "borg286" {
  username             = "borg286"
  login_name           = "borg286"
  email                = "borg286@gmail.com"
  password             = var.borg286_password
  must_change_password = false
}

resource "gitea_team_membership" "borg286_devs" {
  team_id  = gitea_team.devs.id
  username = gitea_user.borg286.username
}

provider "gitea" {
  alias    = "borg286"
  base_url = "http://forgejo-http.forgejo:3000"
  username = gitea_user.borg286.username
  password = var.borg286_password
}

resource "gitea_token" "borg286_token" {
  provider = gitea.borg286
  name     = "code-server-token"
  scopes   = ["all"]
}

provider "kubernetes" {
  # Assumes running in-cluster or with access to default kubeconfig
}

resource "kubernetes_secret" "borg286_git_credentials" {
  metadata {
    name      = "git-credentials"
    namespace = "borg286"
  }

  data = {
    token = gitea_token.borg286_token.token
  }
}
