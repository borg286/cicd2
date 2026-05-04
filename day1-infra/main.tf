terraform {
  required_providers {
    helm       = { source = "hashicorp/helm" }
    kubernetes = { source = "hashicorp/kubernetes" }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config" # Adjust for k3d
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}

variable "forgejo_password" {
  type        = string
  description = "The admin password for Forgejo"
  sensitive   = true
  # No default value means Terraform will prompt you if it's not provided
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
resource "helm_release" "forgejo" {
  name       = "forgejo"
  # For OCI, the full path goes here, NOT in the repository attribute
  chart      = "oci://code.forgejo.org/forgejo-helm/forgejo"
  version    = "17.0.1" # Version is required for OCI charts in Terraform
  
  namespace  = kubernetes_namespace_v1.forgejo.metadata[0].name
  wait       = true

  values = [yamlencode({
    gitea = {
      admin = {
        existingSecret = kubernetes_secret_v1.forgejo_admin.metadata[0].name
        email = "admin@example.com"
      }
      config = {
        server = {
          ROOT_URL = "http://forgejo-http.forgejo.svc.cluster.local:3000/"
        }
      }
    }
  })]
}

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
