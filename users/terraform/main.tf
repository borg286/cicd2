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

variable "borg286_password" {
  type      = string
  sensitive = true
}

resource "gitea_user" "borg286" {
  username   = "borg286"
  login_name = "borg286"
  email      = "borg286@gmail.com"
  password   = var.borg286_password
}
