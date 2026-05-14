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


resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode({
    customization = {
      systemExtensions = {
        officialExtensions = [
          "siderolabs/iscsi-tools",
          "siderolabs/util-linux-tools"
        ]
      }
    }
  })
}


data "talos_image_factory_urls" "this" {
  talos_version = "v1.13.1"
  schematic_id  = resource.talos_image_factory_schematic.this.id
  platform      = "metal"
}

output "talos_installer_url" {
  description = "The generated Talos installer image URL"
  value       = data.talos_image_factory_urls.this.urls.installer
}

resource "talos_machine_configuration_apply" "this" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.this.machine_configuration
  node                        = var.ip_addr
  config_patches = [
    yamlencode({
      machine = {
        install = {
          disk = "/dev/nvme0n1"
          image = data.talos_image_factory_urls.this.urls.installer
          wipe = true
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
      cluster = {
        allowSchedulingOnControlPlanes = true
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

resource "local_file" "kubeconfig" {
  content  = talos_cluster_kubeconfig.this.kubeconfig_raw
  filename = "${path.module}/../../../kubeconfig"
}

resource "local_file" "talosconfig" {
  content  = data.talos_client_configuration.this.talos_config
  filename = "${path.module}/../../../talosconfig"
}