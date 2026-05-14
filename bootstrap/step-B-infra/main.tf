terraform {
  required_providers {
    helm       = { source = "hashicorp/helm" }
    kubernetes = { source = "hashicorp/kubernetes" }
  }
}

provider "kubernetes" {
  config_path = "../../../kubeconfig"
}

provider "helm" {
  repository_config_path = "${path.module}/.helm/repository/config.yaml"
  repository_cache       = "${path.module}/.helm/repository/cache"
  kubernetes = {
    config_path = "../../../kubeconfig"
  }
}

variable "install_longhorn" {
  description = "Enable or disable Longhorn installation."
  type        = bool
  default     = true
}

variable "forgejo_password" {
  type        = string
  description = "The admin password for Forgejo"
  sensitive   = true
  # No default value means Terraform will prompt you if it's not provided
}

# Apply Longhorn namespace and storageclass (YAML manifests are already in the repo).
resource "kubernetes_manifest" "longhorn_namespace" {
  count = var.install_longhorn ? 1 : 0
  manifest = yamldecode(file("${path.module}/longhorn-namespace.yaml"))
}

resource "kubernetes_manifest" "longhorn_storageclass" {
  count = var.install_longhorn ? 1 : 0
  manifest = yamldecode(file("${path.module}/longhorn-storageclass.yaml"))
}

# Install Longhorn via Helm using the supplied values file.
resource "helm_release" "longhorn" {
  count = var.install_longhorn ? 1 : 0
  name       = "longhorn"
  repository = "https://charts.longhorn.io"
  chart      = "longhorn"
  namespace  = "longhorn-system"
  values     = [file("${path.module}/longhorn-values.yaml")]
  depends_on = [kubernetes_manifest.longhorn_namespace]
}

resource "kubernetes_namespace_v1" "forgejo" {
  metadata {
    name = "forgejo"
  }
}

resource "kubernetes_secret_v1" "forgejo_admin" {
metadata {
    name      = "forgejo-admin"
    namespace = kubernetes_namespace_v1.forgejo.metadata[0].name

    labels = {
      # This tells the Flux/Helm controller it's okay to manage this
      "app.kubernetes.io/managed-by" = "Helm"
    }

    annotations = {
      # These must match your helm_release name and namespace
      "meta.helm.sh/release-name"      = "forgejo"
      "meta.helm.sh/release-namespace" = "forgejo"
      # REFLECTOR ANNOTATIONS
      # This mirrors the secret to the flux-system namespace
      "replicate-to"                   = "flux-system"
      # This ensures if you change the password here, it updates in flux-system
      "replicate-reflection-allowed"   = "true"
    }
  }

  type = "Opaque"

  data = {
    username = "forgejo-admin"
    password = var.forgejo_password
  }
}

# 2. Install Forgejo
#resource "helm_release" "forgejo" {
#  name       = "forgejo"
#  # For OCI, the full path goes here, NOT in the repository attribute
#  chart      = "oci://code.forgejo.org/forgejo-helm/forgejo"
#  version    = "17.0.1" # Version is required for OCI charts in Terraform
#  namespace  = kubernetes_namespace_v1.forgejo.metadata[0].name
#  wait       = true
#
#  values = [yamlencode({
#    gitea = {
#      admin = {
#        existingSecret = kubernetes_secret_v1.forgejo_admin.metadata[0].name
#        email = "admin@example.com"
#      }
#      config = {
#        server = {
#          ROOT_URL = "http://forgejo-http.forgejo.svc.cluster.local:3000/"
#        }
#      }
#    }
#  })]
#}

# 3. Install Flux (CRDs and Controllers)
resource "helm_release" "flux" {
  name             = "flux2"
  repository       = "https://fluxcd-community.github.io/helm-charts"
  chart            = "flux2"
  namespace        = "flux-system"
  create_namespace = true
  version          = "2.13.0"

  values = [
    yamlencode({
      installCRDs = true
    })
  ]
}
