terraform {
  required_providers {
    talos = {
      source  = "talos/talos"
      version = "~> 0.5"
    }
  }
}

# Configure the Talos provider – replace placeholder values with your node IPs and SSH keys.
provider "talos" {
  talosconfig_path = var.talosconfig_path
}

# Read the control‑plane patch that adds Longhorn mounts.
data "local_file" "controlplane_patch" {
  filename = var.controlplane_patch_path
}

# Apply the patch to the control plane machine configuration.
resource "talos_machine_config_patch" "controlplane" {
  name       = "controlplane"
  patch_data = data.local_file.controlplane_patch.content
}

# Bootstrap the control‑plane node (example – you may have a different bootstrap method).
resource "talos_machine_bootstrap" "cp" {
  node = var.controlplane_node_ip
  config_patches = [talos_machine_config_patch.controlplane.id]
}

# Variables – user must supply these.
variable "talosconfig_path" {}
variable "controlplane_patch_path" {}
