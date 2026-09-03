provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
  token      = var.token
  profile    = var.profile

  default_tags {
    tags = local.tags
  }
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks", "get-token",
        "--cluster-name", module.eks.cluster_name,
        "--region", var.region,
      ]
      env = merge(
        {
          AWS_REGION         = var.region
          AWS_DEFAULT_REGION = var.region
        },
        var.access_key != null ? { AWS_ACCESS_KEY_ID = var.access_key } : {},
        var.secret_key != null ? { AWS_SECRET_ACCESS_KEY = var.secret_key } : {},
        var.token != null ? { AWS_SESSION_TOKEN = var.token } : {},
        var.profile != null && var.access_key == null ? { AWS_PROFILE = var.profile } : {},
      )
    }
  }
}
