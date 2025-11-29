module "eks_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0" # Specify a desired version

  name = "eks-vpc"
  cidr = "10.128.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets = ["10.128.1.0/24", "10.128.2.0/24", "10.128.3.0/24"]
  public_subnets  = ["10.128.101.0/24", "10.128.102.0/24", "10.128.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Environment = "Development"
    # Project     = "MyApplication"
  }
}

resource "aws_eks_cluster" "eks_lab" {
  name = "eks-lab"

  access_config {
    authentication_mode = "API"
  }
  bootstrap_self_managed_addons = true # install coredns and kuneproxy as default 

  role_arn = aws_iam_role.cluster.arn
  version  = "1.33"

  vpc_config {
    subnet_ids              = module.eks_vpc.private_subnets
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs = ["156.155.134.188/32",
    ]
  }

  # Ensure that IAM Role permissions are created before and deleted
  # after EKS Cluster handling. Otherwise, EKS will not be able to
  # properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]

  upgrade_policy {
    support_type = "STANDARD"
  }

  enabled_cluster_log_types = ["audit", "authenticator"] # ["api","audit","authenticator","controllerManager","scheduler"]
}

resource "aws_iam_role" "cluster" {
  name = "eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}


resource "aws_iam_role" "worker_nodes" {
  name = "eks-worker-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

}



resource "aws_iam_role_policy_attachment" "worker_node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.worker_nodes.name
}

resource "aws_iam_role_policy_attachment" "worker_node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.worker_nodes.name
}

resource "aws_iam_role_policy_attachment" "worker_node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.worker_nodes.name
}


resource "aws_eks_node_group" "spot" {
  cluster_name    = aws_eks_cluster.eks_lab.name
  node_group_name = "spot"
  node_role_arn   = aws_iam_role.worker_nodes.arn
  subnet_ids      = module.eks_vpc.private_subnets # aws_subnet.example[*].id
  capacity_type   = "SPOT"
  ami_type        = "AL2023_x86_64_STANDARD"
  instance_types  = ["t3a.small", "t3.small"] # "t3a.medium",	"t3.medium"

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  # Optional: Add labels, taints, or update configuration
  labels = {
    env           = "dev"
    capacity_type = "spot"
  }
  timeouts {
    create = "10m" // Allow 10 minutes for instance creation
    delete = "5m"  // Allow 5 minutes for instance deletion
    update = "15m" // Allow 15 minutes for instance updates
  }
  tags = {
    Name = "eks-spot-node-group"
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.worker_node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.worker_node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.worker_node_AmazonEKS_CNI_Policy,
    # aws_eks_addon.vpc_cni
  ]
}

# https://registry.terraform.io/providers/hashicorp/aws/6.12.0/docs/resources/eks_node_group
resource "aws_eks_node_group" "on_demand" {
  cluster_name    = aws_eks_cluster.eks_lab.name
  node_group_name = "on_demand"
  node_role_arn   = aws_iam_role.worker_nodes.arn
  subnet_ids      = module.eks_vpc.private_subnets # aws_subnet.example[*].id
  capacity_type   = "ON_DEMAND"
  ami_type        = "AL2023_x86_64_STANDARD"
  instance_types  = ["t3a.small", "t3.small"] # "t3a.medium",	"t3.medium"

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  # Optional: Add labels, taints, or update configuration
  labels = {
    env           = "dev"
    capacity_type = "on_demand"
  }

  tags = {
    Name = "eks-on-demand-node-group"
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.worker_node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.worker_node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.worker_node_AmazonEKS_CNI_Policy,
    # aws_eks_addon.vpc_cni
  ]
}



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


resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.eks_lab.name
  addon_name   = "vpc-cni"
  # addon_version               = "v1.10.1-eksbuild.1" #e.g., previous version v1.9.3-eksbuild.3 and the new version is v1.10.1-eksbuild.1
  resolve_conflicts_on_update = "PRESERVE"
}

resource "aws_iam_policy" "AWSLoadBalancerControllerIAMPolicy" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "AWSLoadBalancerControllerIAMPolicy"
  policy      = file("AWSLoadBalancerControllerIAMPolicy.json")
}

# data "aws_iam_policy_document" "assume_role_AWSLoadBalancerControllerIAMPolicy" {
#   statement {
#     effect = "Allow"

#     principals {
#       type        = "Service"
#       identifiers = ["pods.eks.amazonaws.com"]
#     }

#     actions = [
#       "sts:AssumeRole",
#       "sts:TagSession"
#     ]
#   }
# }

# resource "aws_iam_role" "AWSLoadBalancerControllerIAMPolicy" {
#   name               = "eks-pod-identity-example_AWSLoadBalancerControllerIAMPolicy"
#   assume_role_policy = data.aws_iam_policy_document.assume_role_AWSLoadBalancerControllerIAMPolicy.json
# }

# resource "aws_iam_role_policy_attachment" "example_s3" {
#   policy_arn =  aws_iam_policy.alb.arn
#   role       = aws_iam_role.AWSLoadBalancerControllerIAMPolicy.name
# }

# resource "aws_eks_pod_identity_association" "AWSLoadBalancerControllerIAMPolicy" {
#   cluster_name    = aws_eks_cluster.eks_lab.name
#   namespace       = "kube-system"
#   service_account = "aws-load-balancer-controller"
#   role_arn        = aws_iam_role.AWSLoadBalancerControllerIAMPolicy.arn
# } 


