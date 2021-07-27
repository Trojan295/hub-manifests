module "vpc" {
  source = "git::https://repo1.dso.mil/platform-one/big-bang/customers/template.git//terraform/modules/vpc?ref=1.1.1"

  name       = "${local.name}-vpc"
  aws_region = var.aws_region
  vpc_cidr   = var.vpc_cidr

  tags = merge(local.tags, var.tags)
}
