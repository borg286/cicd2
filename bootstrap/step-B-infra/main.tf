terraform {
  required_providers {
    helm       = { source = "hashicorp/helm" }
    kubernetes = { source = "hashicorp/kubernetes" }
  }
}

locals {
  forgejo_dir = "${path.module}/../../clusters/main/forgejo"

  # Extra manifests from cluster folder
  forgejo_cluster_manifest_files = [
    "forgejo-auth-proxy.yaml"
  ]
  
  # Extra manifests from bootstrap folder (skeleton)
  forgejo_bootstrap_manifest_files = [
    "skeleton-rbac.yaml"
  ]
  
  forgejo_extra_manifests = flatten([
    # Cluster manifests
    [for f in local.forgejo_cluster_manifest_files : [
      for doc in split("---", file("${local.forgejo_dir}/${f}")) : yamldecode(doc) if trimspace(doc) != ""
    ]],
    # Bootstrap manifests
    [for f in local.forgejo_bootstrap_manifest_files : [
      for doc in split("---", file("${path.module}/${f}")) : yamldecode(doc) if trimspace(doc) != ""
    ]]
  ])
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

# 2. Install Flux (CRDs and Controllers)
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

# 3. Install Forgejo (Relying on Flux CRDs via kubernetes_manifest)
resource "kubernetes_manifest" "forgejo_helm_repo" {
  manifest = yamldecode(file("${local.forgejo_dir}/helm-repo.yaml"))
  
  # Wait for Flux to be installed so the HelmRepository CRD exists
  depends_on = [helm_release.flux]
}

resource "kubernetes_manifest" "forgejo_helm_release" {
  manifest = yamldecode(file("${local.forgejo_dir}/helm-release.yaml"))
  
  # Wait for Flux and the repository to be ready
  depends_on = [
    helm_release.flux, 
    kubernetes_manifest.forgejo_helm_repo,
    kubernetes_secret_v1.forgejo_admin
  ]
}

# Apply extra Forgejo manifests (Auth Proxy, RBAC, etc.)
resource "kubernetes_manifest" "forgejo_extra" {
  for_each = {
    for m in local.forgejo_extra_manifests :
    "${m.kind}--${m.metadata.name}--${lookup(m.metadata, "namespace", "cluster")}" => m
  }

  manifest = each.value

  # Depends on the namespace being ready
  depends_on = [kubernetes_namespace_v1.forgejo]
}

