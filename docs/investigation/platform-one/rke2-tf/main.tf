locals {
  name = "bigbang-${var.env}"

  # Bigbang specific OS tuning
  os_prep = <<EOF

#
# Configure mirror for the registry1.dso.mil
#

# Configure /etc/hosts # TODO: Make it configurable
sudo mkdir -p /etc/rancher/rke2
sudo tee -a /etc/rancher/rke2/registries.yaml > /dev/null cat <<EOT
mirrors:
  "registry1.dso.mil":
    endpoint:
      - 347763108806.dkr.ecr.eu-west-1.amazonaws.com
EOT

#
# Fix network issues
#

# https://github.com/rancher/rke2/issues/1053
# https://github.com/projectcalico/calico/issues/4662

# delete IP route entry which causes failure to avoid rebooting the node
sudo ip rule del table 30400

# Disable services which causes
systemctl disable nm-cloud-setup.service
systemctl disable nm-cloud-setup.timer

# Prepare config for NetworkManager
sudo mkdir -p /etc/NetworkManager/conf.d
sudo tee -a /etc/NetworkManager/conf.d/rke2-canal.conf > /dev/null cat <<EOT
[keyfile]
unmanaged-devices=interface-name:cali*;interface-name:flannel*
EOT

#
# Big-bang specific tuning
#

# Configure aws cli default region to current region, it'd be great if the aws cli did this on install........
aws configure set default.region $(curl -s http://169.254.169.254/latest/meta-data/placement/region)

# Tune vm sysctl for elasticsearch
sysctl -w vm.max_map_count=524288

# SonarQube host pre-requisites
sysctl -w fs.file-max=131072
ulimit -n 131072
ulimit -u 8192

# Preload kernel modules required by istio-init, required for selinux enforcing instances using istio-init
modprobe xt_REDIRECT
modprobe xt_owner
modprobe xt_statistic
# Persist modules after reboots
printf "xt_REDIRECT\nxt_owner\nxt_statistic\n" | sudo tee -a /etc/modules
EOF

  tags = {
    "project"         = "platform-one"
    "env"             = var.env
    "terraform"       = "true"
  }
}

# Private Key
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "pem" {
  filename        = "rke2.pem"
  content         = tls_private_key.ssh.private_key_pem
  file_permission = "0600"
}

module "rke2" {
  source = "git::https://repo1.dso.mil/platform-one/distros/rancher-federal/rke2/rke2-aws-terraform.git?ref=v1.1.9"

  cluster_name          = local.name
  vpc_id                = module.vpc.vpc_id
  subnets               = module.vpc.public_subnets
  ami                   = var.server_ami
  servers               = var.servers
  instance_type         = var.server_instance_type
  controlplane_internal = var.controlplane_internal
  rke2_version          = var.rke2_version
  ssh_authorized_keys = [tls_private_key.ssh.public_key_openssh]

  rke2_config = <<EOF
disable:
  - rke2-ingress-nginx
EOF

  enable_ccm = var.enable_ccm
  download   = var.download

  pre_userdata = local.os_prep

  tags = merge({}, local.tags, var.tags)
}

module "generic_agents" {
  source = "git::https://repo1.dso.mil/platform-one/distros/rancher-federal/rke2/rke2-aws-terraform.git//modules/agent-nodepool?ref=v1.1.9"

  name                = "generic-agent"
  vpc_id              = module.vpc.vpc_id
  subnets             = module.vpc.public_subnets
  ami                 = var.agent_ami
  asg                 = var.agent_asg
  spot                = var.agent_spot
  instance_type       = var.agent_instance_type
   ssh_authorized_keys = [tls_private_key.ssh.public_key_openssh]
  rke2_version        = var.rke2_version

  enable_ccm        = var.enable_ccm
  enable_autoscaler = var.enable_autoscaler
  download          = var.download

  # TODO: These need to be set in pre-baked ami's
  pre_userdata = local.os_prep

  # Required data for identifying cluster to join
  cluster_data = module.rke2.cluster_data

  tags = merge({}, local.tags, var.tags)
}

# Example method of fetching kubeconfig from state store, requires aws cli
resource "null_resource" "kubeconfig" {
  depends_on = [module.rke2]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "aws s3 cp ${module.rke2.kubeconfig_path} rke2.yaml"
  }
}

## Adding tags on VPC and Subnets to match uniquely created cluster name
resource "aws_ec2_tag" "vpc_tags" {
  resource_id = module.vpc.vpc_id
  key         = "kubernetes.io/cluster/${module.rke2.cluster_name}"
  value       = "shared"
}

resource "aws_ec2_tag" "public_subnets_tags" {
  count       = length(module.vpc.public_subnets)
  resource_id = module.vpc.public_subnets[count.index]
  key         = "kubernetes.io/cluster/${module.rke2.cluster_name}"
  value       = "shared"
}

resource "aws_ec2_tag" "private_subnets_tags" {
  count       = length(module.vpc.private_subnets)
  resource_id = module.vpc.private_subnets[count.index]
  key         = "kubernetes.io/cluster/${module.rke2.cluster_name}"
  value       = "shared"
}


resource "aws_security_group_rule" "dev-ssh" {
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id =  module.rke2.cluster_data.cluster_sg
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

output "cluster_sg" {
  description = "Cluster SG ID, used for dev ssh access"
  value = module.rke2.cluster_data.cluster_sg
}