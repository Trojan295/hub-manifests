module "bastion" {
  source  = "cloudposse/ec2-bastion-server/aws"
  version = "0.28.3"

  enabled = var.enable_bastion

  name          = "${local.name}-bastion"
  key_name      = module.ssh.key_name
  instance_type = var.bastion_instance_type

  ssh_user = "ec2-user"

  vpc_id                      = module.vpc.vpc_id
  subnets                     = module.vpc.public_subnet_ids
  associate_public_ip_address = true

  tags = merge(local.tags, var.tags)
}
