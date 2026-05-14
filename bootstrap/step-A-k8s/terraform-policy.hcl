# For KV-V2, permissions must explicitly include the "data" prefix
path "secret/data/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# This is also needed for Terraform to check metadata
path "secret/metadata/*" {
  capabilities = ["list", "read", "delete"]
}

# Keep the token creation permission from before
path "auth/token/create" {
  capabilities = ["update"]
}