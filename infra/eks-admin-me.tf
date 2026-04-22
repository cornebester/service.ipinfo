resource "aws_eks_access_entry" "caller" {
  cluster_name  = aws_eks_cluster.eks_lab.name
  principal_arn = data.aws_iam_session_context.current.issuer_arn
  # kubernetes_groups = ["group-1", "group-2"]
  type = "STANDARD"
}

resource "aws_eks_access_policy_association" "caller_AmazonEKSAdminPolicy" {
  cluster_name  = aws_eks_cluster.eks_lab.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
  principal_arn = data.aws_iam_session_context.current.issuer_arn

  access_scope {
    type = "cluster" # "namespace"
    # namespaces = ["example-namespace"]
  }
}

resource "aws_eks_access_policy_association" "caller_AmazonEKSClusterAdminPolicy" {
  cluster_name  = aws_eks_cluster.eks_lab.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = data.aws_iam_session_context.current.issuer_arn

  access_scope {
    type = "cluster" # "namespace"
    # namespaces = ["example-namespace"]
  }
}
