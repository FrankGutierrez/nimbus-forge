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
  host = "https://kubernetes.docker.internal:6443"
  config_context_cluster = "docker-desktop"
  config_path = "~/.kube/config"
}
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}
provider "kubectl" {
  config_path = "~/.kube/config"
  config_context_cluster = "docker-desktop"
  host = "https://kubernetes.docker.internal:6443"
}