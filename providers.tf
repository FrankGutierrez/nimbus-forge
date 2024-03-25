terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.27.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.12.1"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "2.0.4"
    }
  }
}



provider "kubernetes" {
  # Configuration options
  host = var.kube_config_host
  config_context_cluster = var.kube_config_context_cluster
  config_path = var.kube_config_path
}
provider "helm" {
  kubernetes {
    config_path = var.kube_config_path
  }
}
provider "kubectl" {
  config_path = var.kube_config_path
  config_context_cluster = var.kube_config_context_cluster
  host = var.kube_config_host
  apply_retry_count = 5
}