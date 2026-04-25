terraform {
  required_providers {
    gitea = {
      source = "gitea/gitea"
      version = "~> 0.1"
    }
  }
}

provider "gitea" {
  base_url = "http://forgejo-http.forgejo:3000"
}

variable "gitea_token" {
  type      = string
  sensitive = true
}

resource "gitea_organization" "my_org" {
  name = "my-org"
}

resource "gitea_repository" "mirror_repo" {
  name        = "cloned-repo"
  username    = gitea_organization.my_org.name
  mirror      = true
  # Placeholder - replace with your actual GitHub repo URL
  # example: "https://github.com/example/repo.git"
}

resource "gitea_user" "flux_user" {
  username = "flux-agent"
  email    = "flux@example.com"
  password = "SecurePassword123" # Replace with a secure password
}
