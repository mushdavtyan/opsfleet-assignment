data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = merge(
    {
      Project     = var.cluster_name
      Environment = "poc"
      ManagedBy   = "terraform"
    },
    var.tags,
  )
}
