variable "env" {
  default = "platform-one"
}
variable "aws_region" {
  default = "eu-west-1" // "us-gov-west-1"
}

variable "tags" {
  type    = map(string)
  default = {}
}

#
# Cluster variables
#
variable "controlplane_internal" {
  default = false
}

variable "enable_ccm" {
  default = true
}

variable "enable_autoscaler" {
  default = true
}

variable "download" {
  type    = bool
  default = true
  description = "Toggle dependency downloading"
}

#
# Server variables
#
variable "server_ami" {
  # RHEL 8.3 RKE2 v1.20.5+rke2r1 STIG: https://repo1.dso.mil/platform-one/distros/rancher-federal/rke2/rke2-image-builder
  default = "ami-0ec23856b3bad62d3" # RHEL-8
}
variable "server_instance_type" {
  default = "m5a.large"
}
variable "servers" {
  default = 1
}
variable "rke2_version" {
  default = "v1.20.5+rke2r1"
}

#
# Generic agent variables
#
variable "agent_ami" {
  # RHEL 8.3 RKE2 v1.20.5+rke2r1 STIG: https://repo1.dso.mil/platform-one/distros/rancher-federal/rke2/rke2-image-builder
  default = "ami-0ec23856b3bad62d3" # RHEL-8
}
variable "agent_instance_type" {
  default = "m5a.4xlarge"
}
variable "agent_asg" {
  default = { min : 2, max : 10, desired : 2 }
}
variable "agent_spot" {
  default = false
}
