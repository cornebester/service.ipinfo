provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = aws_eks_cluster.eks_lab.arn
}


resource "kubernetes_namespace" "depreciated" {
  metadata {
    name = "my-first-namespace"
  }
}

resource "kubernetes_namespace_v1" "my-second-namespace" {
  metadata {
    name = "my-second-namespace"
  }
}