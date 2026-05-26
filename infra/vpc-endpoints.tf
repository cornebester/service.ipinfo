# Security group for VPC endpoints
resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "eks-vpc-endpoints-"
  description = "Security group for VPC endpoints"
  vpc_id      = module.eks_vpc.vpc_id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.eks_vpc.vpc_cidr_block]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "eks-vpc-endpoints-sg"
    Environment = "Development"
  }
}

# VPC Endpoint for EC2
resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = module.eks_vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.eks_vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "eks-ec2-endpoint"
    Environment = "Development"
  }
}

# VPC Endpoint for ECR API
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = module.eks_vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.eks_vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "eks-ecr-api-endpoint"
    Environment = "Development"
  }
}

# VPC Endpoint for ECR Docker
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = module.eks_vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.eks_vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "eks-ecr-dkr-endpoint"
    Environment = "Development"
  }
}

# VPC Endpoint for S3 (Gateway endpoint - no cost)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.eks_vpc.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat(module.eks_vpc.private_route_table_ids, module.eks_vpc.public_route_table_ids)

  tags = {
    Name        = "eks-s3-endpoint"
    Environment = "Development"
  }
}

# VPC Endpoint for CloudWatch Logs
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = module.eks_vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.eks_vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "eks-logs-endpoint"
    Environment = "Development"
  }
}

# VPC Endpoint for STS
resource "aws_vpc_endpoint" "sts" {
  vpc_id              = module.eks_vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.sts"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.eks_vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "eks-sts-endpoint"
    Environment = "Development"
  }
}

# VPC Endpoint for Elastic Load Balancing (needed for AWS Load Balancer Controller)
resource "aws_vpc_endpoint" "elasticloadbalancing" {
  vpc_id              = module.eks_vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.elasticloadbalancing"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.eks_vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "eks-elb-endpoint"
    Environment = "Development"
  }
}

# VPC Endpoint for autoscaling (needed for cluster autoscaler)
resource "aws_vpc_endpoint" "autoscaling" {
  vpc_id              = module.eks_vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.autoscaling"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.eks_vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "eks-autoscaling-endpoint"
    Environment = "Development"
  }
}

# VPC Endpoint for Secrets Manager
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = module.eks_vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.eks_vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "eks-secretsmanager-endpoint"
    Environment = "Development"
  }
}

# VPC Endpoint for EKS API
resource "aws_vpc_endpoint" "eks" {
  vpc_id              = module.eks_vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.eks"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.eks_vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "eks-api-endpoint"
    Environment = "Development"
  }
}
