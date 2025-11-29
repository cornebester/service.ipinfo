# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "~> 21.0"

#   name               = "my-cluster"
#   kubernetes_version = "1.33"

#   addons = {
#     coredns = {}
#     eks-pod-identity-agent = {
#       before_compute = true
#     }
#     kube-proxy = {}
#     vpc-cni = {
#       before_compute = true
#     }
#   }

#   # Optional
#   endpoint_public_access = true

#   # Optional: Adds the current caller identity as an administrator via cluster access entry
#   enable_cluster_creator_admin_permissions = true

#   vpc_id                   = module.eks_vpc.vpc_id
#   subnet_ids               = module.eks_vpc.private_subnets #["subnet-abcde012", "subnet-bcde012a", "subnet-fghi345a"]
#   control_plane_subnet_ids = module.eks_vpc.private_subnets # ["subnet-xyzde987", "subnet-slkjf456", "subnet-qeiru789"]

#   # EKS Managed Node Group(s)
#   eks_managed_node_groups = {
#     spot_group1 = {
#       # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
#       ami_type = "AL2023_x86_64_STANDARD"
#       name     = "spot-group1"

#       instance_types = ["t3.medium"]
#       capacity_type  = "SPOT"

#       min_size     = 1
#       max_size     = 2
#       desired_size = 1
#     }
#   }

#   tags = {
#     Environment = "dev"
#     Terraform   = "true"
#   }
# }
