terraform {
  required_providers {
    gitea = {
      source = "go-gitea/gitea"
      version = "~> 0.7.0"
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

resource "gitea_org" "my_org" {
  name = "my-org"
}

resource "gitea_repository" "mirror_repo" {
  name        = "cloned-repo"
  username    = gitea_org.my_org.name
  mirror      = true
  # Placeholder - replace with your actual GitHub repo URL
  # example: "https://github.com/example/repo.git"
}

resource "gitea_user" "flux_user" {
  username   = "flux-agent"
  login_name = "flux-agent"
  email      = "flux@example.com"
  password   = "SecurePassword123" # Replace with a secure password
}
