# main.yaml (alternative - using existing files)
terraform {
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.11.0"
    }
  }
}

# Variables
variable "talosconfig_path" {
  description = "Path to the talosconfig file"
  type        = string
  default     = "../../talosconfig"
}

variable "node_ip" {
  description = "IP address or hostname of the Talos node"
  type        = string
}

# Read existing talosconfig
locals {
  talosconfig_raw = yamldecode(file(var.talosconfig_path))
  talos_context   = local.talosconfig_raw.contexts[local.talosconfig_raw.context]
  
  # Extract client configuration from existing talosconfig
  client_configuration = {
    ca_certificate     = base64encode(local.talos_context.ca)
    client_certificate = base64encode(local.talos_context.crt)
    client_key         = base64encode(local.talos_context.key)
  }
}

# Apply configuration with patches using the existing client config
resource "talos_machine_configuration_apply" "controlplane" {
  client_configuration        = local.client_configuration
  machine_configuration_input = file("../../controlplane.yaml")
  node                        = var.node_ip
  apply_mode                  = "no_reboot"

  config_patches = [
    file("${path.module}/controlplane-patch.yaml")
  ]
}


# Optional: Bootstrap the node if this is a fresh cluster
# resource "talos_machine_bootstrap" "this" {
#   depends_on = [
#     talos_machine_configuration_apply.controlplane
#   ]
#   node                 = var.node_ip
#   client_configuration = local.client_configuration
# }