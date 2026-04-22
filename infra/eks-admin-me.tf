resource "aws_eks_access_entry" "corne" {
  cluster_name  = aws_eks_cluster.eks_lab.name
  principal_arn = "arn:aws:iam::146632099925:user/corne.bester" # aws_iam_role.example.arn
  # kubernetes_groups = ["group-1", "group-2"]
  type = "STANDARD"
}

resource "aws_eks_access_policy_association" "corne_AmazonEKSAdminPolicy" {
  cluster_name  = aws_eks_cluster.eks_lab.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
  principal_arn = "arn:aws:iam::146632099925:user/corne.bester"

  access_scope {
    type = "cluster" # "namespace"
    # namespaces = ["example-namespace"]
  }
}

resource "aws_eks_access_policy_association" "corne_AmazonEKSClusterAdminPolicy" {
  cluster_name  = aws_eks_cluster.eks_lab.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = "arn:aws:iam::146632099925:user/corne.bester"

  access_scope {
    type = "cluster" # "namespace"
    # namespaces = ["example-namespace"]
  }
}
