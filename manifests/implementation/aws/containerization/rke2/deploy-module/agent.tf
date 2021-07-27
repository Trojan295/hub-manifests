module "agents" {
  source = "git::https://repo1.dso.mil/platform-one/distros/rancher-federal/rke2/rke2-aws-terraform.git//modules/agent-nodepool?ref=v1.1.9"

  name              = "generic"
  vpc_id            = module.vpc.vpc_id
  subnets           = module.vpc.private_subnet_ids
  ami               = var.agent_ami
  asg               = var.agent_asg
  instance_type     = var.agent_instance_type
  rke2_version      = var.rke2_version
  enable_autoscaler = var.enable_autoscaler
  enable_ccm        = var.enable_ccm
  download          = var.nodes_download_dependencies
  spot              = var.use_spot_agents

  ssh_authorized_keys = [module.ssh.public_key]

  pre_userdata = local.user_data

  # Required data for identifying cluster to join
  cluster_data = module.server.cluster_data

  tags = merge(local.tags, var.tags)
}
