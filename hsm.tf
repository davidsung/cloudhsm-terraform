resource "aws_cloudhsm_v2_cluster" "hsm_cluster" {
  hsm_type   = "hsm1.medium"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name        = "hsm_cluster"
    Environment = var.environment
  }
}

data "aws_cloudhsm_v2_cluster" "hsm_cluster" {
  cluster_id = aws_cloudhsm_v2_cluster.hsm_cluster.cluster_id
}

resource "aws_cloudhsm_v2_hsm" "hsm" {
  subnet_id  = module.vpc.private_subnets.0
  cluster_id = data.aws_cloudhsm_v2_cluster.hsm_cluster.cluster_id
}
