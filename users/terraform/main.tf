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

# Placeholder for users. Add a resource for each user like this:
# resource "gitea_user" "user_name" {
#   username   = "user_name"
#   login_name = "user_name"
#   email      = "user@example.com"
#   password   = "some_initial_password" # Or use a variable
# }
