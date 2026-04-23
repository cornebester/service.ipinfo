# 1. Create the Access Entry for the IAM Role
resource "aws_eks_access_entry" "named_user_or_role" {
  cluster_name  = aws_eks_cluster.eks_lab.name
  principal_arn = var.my_iam_user_arn
  #   kubernetes_groups = ["my-namespace-viewers"]
  type = "STANDARD"
}

# # 2. Associate a Policy with the Access Entry
# resource "aws_eks_access_policy_association" "example" {
#   cluster_name  = "eks-lab"
#   policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
#   principal_arn = aws_eks_access_entry.named_user_or_role.principal_arn

#   access_scope {
#     type       = "namespace"
#     namespaces = ["my-namespace"]
#   }
# }


resource "aws_eks_access_policy_association" "named_user_or_role_AmazonEKSAdminPolicy" {
  cluster_name  = aws_eks_cluster.eks_lab.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
  principal_arn = aws_eks_access_entry.named_user_or_role.principal_arn

  access_scope {
    type = "cluster" # "namespace"
    # namespaces = ["example-namespace"]
  }
}

resource "aws_eks_access_policy_association" "named_user_or_role_AmazonEKSClusterAdminPolicy" {
  cluster_name  = aws_eks_cluster.eks_lab.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_eks_access_entry.named_user_or_role.principal_arn

  access_scope {
    type = "cluster" # "namespace"
    # namespaces = ["example-namespace"]
  }
}