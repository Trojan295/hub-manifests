variable "namespace" {
  type        = string
  description = "Prefix added to all resource names"
  default     = "platform-one"
}

variable "aws_region" {
  type        = string
  description = "AWS region in which RKE2 will be deployed"
  default     = "eu-west-1"
}

variable "tags" {
  type        = map(string)
  description = "Tags added to all taggable AWS resources"
  default     = {}
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR of the VPC"
  default     = "10.0.0.0/16"
}

#
# Cluster variables
#
variable "controlplane_internal" {
  type        = bool
  description = "Toggle between public or private control plane load balancer."
  default     = false
}

variable "enable_ccm" {
  type        = bool
  description = "Makes the cluster AWS aware; this will ensure the appropriate IAM policies are present."
  default     = true
}

#
# Generic node variables
#

variable "registries_config" {
  type        = string
  description = "Content of the /etc/rancher/rke2/registries.yaml file. It will not be created if this is empty."
  default     = <<EOF
mirrors:
  "registry1.dso.mil":
    endpoint:
      - 347763108806.dkr.ecr.eu-west-1.amazonaws.com
EOF
}

variable "user_data" {
  type        = string
  description = "Usedata to run on all the nodes in the cluster."
  default     = <<EOF
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
}

variable "nodes_download_dependencies" {
  type        = bool
  description = "Toggle best effort download of RKE2 dependencies (rke2 and aws cli). If disabled, dependencies are assumed to exist in $PATH."
  default     = true
}

#
# Server variables
#
variable "server_ami" {
  type        = string
  description = "AMI ID for the RKE2 server nodes"
  default     = "ami-0ec23856b3bad62d3" # RHEL-8
}

variable "server_instance_type" {
  type        = string
  description = "Instance type of the RKE2 server nodes"
  default     = "m5a.large"
}

variable "servers" {
  type        = number
  description = "Count of RKE2 server nodes"
  default     = 1
}

variable "rke2_version" {
  type        = string
  description = "Version of the RKE2 cluster"
  default     = "v1.20.5+rke2r1"
}

#
# Generic agent variables
#
variable "agent_ami" {
  type        = string
  description = "AMI ID for the RKE2 agent nodes"
  default     = "ami-0ec23856b3bad62d3" # RHEL-8
}

variable "agent_instance_type" {
  type        = string
  description = "Instance type of the RKE2 agent nodes"
  default     = "m5a.4xlarge"
}

variable "agent_asg" {
  type        = map(number)
  description = "Configuration for the RKE2 agent nodes Auto Scaling Group"
  default     = { min : 2, max : 10, desired : 4 }
}

variable "use_spot_agents" {
  type        = bool
  description = "Toggle spot requests for server pool."
  default     = false
}

variable "enable_autoscaler" {
  type        = bool
  description = "Toggle configuration of the nodepool for cluster autoscaler. This will ensure the appropriate IAM policies are present. You are still responsible for ensuring cluster autoscaler is installed."
  default     = true
}

#
# Bastion variables
#

variable "enable_bastion" {
  type        = bool
  description = "Toggle deploying the bastion host"
  default     = true
}

variable "bastion_instance_type" {
  type        = string
  description = "Instance type of the bastion node"
  default     = "t3.micro"
}
