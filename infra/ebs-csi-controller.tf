resource "aws_eks_addon" "aws-ebs-csi-driver" {
  cluster_name = aws_eks_cluster.eks_lab.name
  addon_name   = "aws-ebs-csi-driver"
  # addon_version               = "v1.10.1-eksbuild.1" #e.g., previous version v1.9.3-eksbuild.3 and the new version is v1.10.1-eksbuild.1
  resolve_conflicts_on_update = "PRESERVE"
  service_account_role_arn    = aws_iam_role.ebs-csi-controller-sa.arn
}

data "aws_iam_policy_document" "ebs-csi-controller-sa_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks_oidc.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "ebs-csi-controller-sa" {
  name               = "ebs-csi-controller-sa-role"
  assume_role_policy = data.aws_iam_policy_document.ebs-csi-controller-sa_role.json
}

resource "aws_iam_role_policy_attachment" "ebs-csi-controller-sa" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEBSCSIDriverPolicyV2"
  role       = aws_iam_role.ebs-csi-controller-sa.name
}