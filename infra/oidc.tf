# Get the TLS certificate for the OIDC provider
data "tls_certificate" "eks_oidc" {
  url = aws_eks_cluster.eks_lab.identity[0].oidc[0].issuer
}
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider

# Create the OIDC provider
resource "aws_iam_openid_connect_provider" "eks_oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks_lab.identity[0].oidc[0].issuer

  tags = {
    Name = "${aws_eks_cluster.eks_lab.name}-oidc-provider"
  }
}