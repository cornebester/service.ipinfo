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

# AWS Load Balancer Controller Service Account
resource "kubernetes_service_account_v1" "alb_controller" {
  metadata {
    name      = "eks-alb-controller-role"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller.arn
    }
  }

  depends_on = [
    aws_eks_cluster.eks_lab,
    aws_iam_role.alb_controller,
    aws_iam_openid_connect_provider.eks_oidc
  ]
}

# EBS CSI Controller Service Account
resource "kubernetes_service_account_v1" "ebs_csi_controller" {
  metadata {
    name      = "ebs-csi-controller-sa"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.ebs-csi-controller-sa.arn
    }
  }

  depends_on = [
    aws_eks_cluster.eks_lab,
    aws_iam_role.ebs-csi-controller-sa,
    aws_iam_openid_connect_provider.eks_oidc
  ]
}