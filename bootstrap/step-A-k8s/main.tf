terraform {
  required_version = ">= 1.11"
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.11"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.0"
    }
  }
}
resource "talos_machine_secrets" "this" {}

variable "ip_addr" {
  type  = string
}

data "talos_machine_configuration" "this" {
  cluster_name     = "example-cluster"
  machine_type     = "controlplane"
  cluster_endpoint = "https://${var.ip_addr}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

data "talos_client_configuration" "this" {
  cluster_name         = "example-cluster"
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = [var.ip_addr]
}

resource "talos_machine_configuration_apply" "this" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.this.machine_configuration
  node                        = var.ip_addr
  config_patches = [
    yamlencode({
      machine = {  # Keep this, but ensure everything else is inside it
        install = {
          disk = "/dev/nvme0n1"
          wipe = true
          extensions = [
            { image = "ghcr.io/siderolabs/iscsi-tools:v0.1.4" },
            { image = "ghcr.io/siderolabs/util-linux-tools:v0.1.0" }
          ]
        }
        registries = {
          mirrors = {
            "docker.io" = {
              endpoints = ["http://zot-registry.zot-system.svc.cluster.local:5000"]
            }
          }
          config = {
            "zot-registry.zot-system.svc.cluster.local:5000" = {
              tls = {}
            }
          }
        }
        sysctls = {
          "vm.nr_hugepages" = "1024"
        }
        kernel = {
          modules = [
            { name = "nvme_tcp" },
            { name = "vfio_pci" }
          ]
        }
        kubelet = {
          extraMounts = [
            {
              destination = "/var/lib/longhorn"
              type        = "bind"
              source      = "/var/lib/longhorn"
              options     = ["bind", "rshared", "rw"]
            }
          ]
        }
      }
    })
  ]
}


resource "talos_machine_bootstrap" "this" {
  depends_on = [
    talos_machine_configuration_apply.this
  ]
  node                 = var.ip_addr
  client_configuration = talos_machine_secrets.this.client_configuration
}


resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this
  ]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = var.ip_addr
}
#print out talos kubeconfig
output "talos_kubeconfig" {
  value = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}
#print out talos_machine_secrets
output "talos_machine_secrets" {
  value = talos_machine_secrets.this.machine_secrets
  sensitive = true
}
