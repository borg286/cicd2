terraform {
  required_providers {
    gitea = { source = "go-gitea/gitea" }
    kubernetes = { source = "hashicorp/kubernetes" }
  }
}

variable "token" {
  type      = string
  sensitive = true
}
variable "admin_username" {
  type      = string
}
variable "admin_password" {
  type      = string
  sensitive = true
}

provider "gitea" {
  base_url = "http://forgejo-http.forgejo:3000"
  token    = var.token
}

provider "kubernetes" {
  # Configured via Tofu-controller service account
}

resource "gitea_team" "devs" {
  name         = "Devs"
  organisation = "main-org"
  description  = "Devs of my-org"
  permission   = "write"
}

# Now hiring borg286 is just these 6 lines
module "user_borg286" {
  source   = "./modules/forgejo-user"
  username = "borg286"
  email    = "borg286@gmail.com"
  team_id  = gitea_team.devs.id
  token = var.token
  admin_username = var.admin_username
  admin_password = var.admin_password
}
