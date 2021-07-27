module "server" {
  source = "git::https://repo1.dso.mil/platform-one/distros/rancher-federal/rke2/rke2-aws-terraform.git?ref=v1.1.9"

  cluster_name          = local.name
  vpc_id                = module.vpc.vpc_id
  subnets               = module.vpc.public_subnet_ids
  ami                   = var.server_ami
  servers               = var.servers
  instance_type         = var.server_instance_type
  rke2_version          = var.rke2_version
  ssh_authorized_keys   = [module.ssh.public_key]
  enable_ccm            = var.enable_ccm
  download              = var.nodes_download_dependencies
  controlplane_internal = var.controlplane_internal

  rke2_config = <<EOF
disable:
  - rke2-ingress-nginx
EOF

  pre_userdata = local.user_data

  tags = merge(local.tags, var.tags)
}
