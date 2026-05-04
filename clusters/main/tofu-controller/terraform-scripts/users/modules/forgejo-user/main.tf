terraform {
  required_providers {
    gitea      = { source = "go-gitea/gitea" }
    kubernetes = { source = "hashicorp/kubernetes" }
    terracurl = {
      source = "devops-rob/terracurl"
    }
  }
}

variable "username" { type = string }
variable "email"    { type = string }
variable "team_id"  { type = string }
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

resource "random_password" "user_pass" {
  length  = 24
  special = false
}

# 1. Create the user
resource "gitea_user" "new_user" {
  username             = var.username
  login_name           = var.username
  password             = random_password.user_pass.result
  email                = var.email
  must_change_password = false
}


# 3. Add to team
resource "gitea_team_membership" "membership" {
  team_id  = var.team_id
  username = gitea_user.new_user.username # Reference fixed
}

# 2. Use a "bridge" to generate the token via API Sudo
# This bypasses the provider's authentication limitations
resource "terracurl_request" "generate_token" {
  name   = "generate_user_token"
  url    = "http://forgejo-http.forgejo:3000/api/v1/users/${var.username}/tokens"
  method = "POST"
  
  headers = {
    "Authorization" = "Basic ${base64encode("${var.admin_username}:${var.admin_password}")}"
    "Sudo"          = var.username
    "Content-Type"  = "application/json"
    "Accept"        = "application/json"
  }

  response_codes = [201]
  request_body   = jsonencode({
    name   = "flux-automation-token"
    scopes = ["all"]
  })

  lifecycle {
    ignore_changes = [request_body] # Prevent re-generating on every run
  }
  depends_on = [gitea_user.new_user, gitea_team_membership.membership]
}


resource "kubernetes_secret_v1" "git_credentials" {
  metadata {
    name      = "git-credentials"
    namespace = var.username
  }
  data = {
    username = var.username
    password = random_password.user_pass.result
    token = jsondecode(terracurl_request.generate_token.response).sha1
  }
}
