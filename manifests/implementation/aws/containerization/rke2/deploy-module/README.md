# Terraform modules to deploy RKE2

This directory stores the Terraform module to deploy a RKE2 environment. It uses the Terraform modules from [https://repo1.dso.mil/platform-one/distros/rancher-federal/rke2/rke2-aws-terraform](https://repo1.dso.mil/platform-one/distros/rancher-federal/rke2/rke2-aws-terraform) and [https://repo1.dso.mil/platform-one/big-bang/customers/template/-/tree/main/terraform/modules](https://repo1.dso.mil/platform-one/big-bang/customers/template/-/tree/main/terraform/modules).

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_local"></a> [local](#provider\_local) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_agents"></a> [agents](#module\_agents) | git::https://repo1.dso.mil/platform-one/distros/rancher-federal/rke2/rke2-aws-terraform.git//modules/agent-nodepool | v1.1.9 |
| <a name="module_bastion"></a> [bastion](#module\_bastion) | cloudposse/ec2-bastion-server/aws | 0.28.3 |
| <a name="module_server"></a> [server](#module\_server) | git::https://repo1.dso.mil/platform-one/distros/rancher-federal/rke2/rke2-aws-terraform.git | v1.1.9 |
| <a name="module_ssh"></a> [ssh](#module\_ssh) | git::https://repo1.dso.mil/platform-one/big-bang/customers/template.git//terraform/modules/ssh | 1.1.1 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | git::https://repo1.dso.mil/platform-one/big-bang/customers/template.git//terraform/modules/vpc | 1.1.1 |

## Resources

| Name | Type |
|------|------|
| [local_file.private_ssh_key](https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_agent_ami"></a> [agent\_ami](#input\_agent\_ami) | AMI ID for the RKE2 agent nodes | `string` | `"ami-0ec23856b3bad62d3"` | no |
| <a name="input_agent_asg"></a> [agent\_asg](#input\_agent\_asg) | Configuration for the RKE2 agent nodes Auto Scaling Group | `map(number)` | <pre>{<br>  "desired": 4,<br>  "max": 10,<br>  "min": 2<br>}</pre> | no |
| <a name="input_agent_instance_type"></a> [agent\_instance\_type](#input\_agent\_instance\_type) | Instance type of the RKE2 agent nodes | `string` | `"m5a.4xlarge"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region in which RKE2 will be deployed | `string` | `"eu-west-1"` | no |
| <a name="input_bastion_instance_type"></a> [bastion\_instance\_type](#input\_bastion\_instance\_type) | Instance type of the bastion node | `string` | `"t3.micro"` | no |
| <a name="input_controlplane_internal"></a> [controlplane\_internal](#input\_controlplane\_internal) | Toggle between public or private control plane load balancer. | `bool` | `false` | no |
| <a name="input_enable_autoscaler"></a> [enable\_autoscaler](#input\_enable\_autoscaler) | Toggle configuration of the nodepool for cluster autoscaler. This will ensure the appropriate IAM policies are present. You are still responsible for ensuring cluster autoscaler is installed. | `bool` | `true` | no |
| <a name="input_enable_bastion"></a> [enable\_bastion](#input\_enable\_bastion) | Toggle deploying the bastion host | `bool` | `true` | no |
| <a name="input_enable_ccm"></a> [enable\_ccm](#input\_enable\_ccm) | Makes the cluster AWS aware; this will ensure the appropriate IAM policies are present. | `bool` | `true` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Prefix added to all resource names | `string` | `"platform-one"` | no |
| <a name="input_nodes_download_dependencies"></a> [nodes\_download\_dependencies](#input\_nodes\_download\_dependencies) | Toggle best effort download of RKE2 dependencies (rke2 and aws cli). If disabled, dependencies are assumed to exist in $PATH. | `bool` | `true` | no |
| <a name="input_registries_config"></a> [registries\_config](#input\_registries\_config) | Content of the /etc/rancher/rke2/registries.yaml file. It will not be created if this is empty. | `string` | `"mirrors:\n  \"registry1.dso.mil\":\n    endpoint:\n      - 347763108806.dkr.ecr.eu-west-1.amazonaws.com\n"` | no |
| <a name="input_rke2_version"></a> [rke2\_version](#input\_rke2\_version) | Version of the RKE2 cluster | `string` | `"v1.20.5+rke2r1"` | no |
| <a name="input_server_ami"></a> [server\_ami](#input\_server\_ami) | AMI ID for the RKE2 server nodes | `string` | `"ami-0ec23856b3bad62d3"` | no |
| <a name="input_server_instance_type"></a> [server\_instance\_type](#input\_server\_instance\_type) | Instance type of the RKE2 server nodes | `string` | `"m5a.large"` | no |
| <a name="input_servers"></a> [servers](#input\_servers) | Count of RKE2 server nodes | `number` | `1` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags added to all taggable AWS resources | `map(string)` | `{}` | no |
| <a name="input_use_spot_agents"></a> [use\_spot\_agents](#input\_use\_spot\_agents) | Toggle spot requests for server pool. | `bool` | `false` | no |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | Usedata to run on all the nodes in the cluster. | `string` | `"#\n# Fix network issues\n#\n\n# https://github.com/rancher/rke2/issues/1053n# https://github.com/projectcalico/calico/issues/4662nn# delete IP route entry which causes failure to avoid rebooting the node\nsudo ip rule del table 30400\n\n# Disable services which causes\nsystemctl disable nm-cloud-setup.service\nsystemctl disable nm-cloud-setup.timer\n\n# Prepare config for NetworkManager\nsudo mkdir -p /etc/NetworkManager/conf.d\nsudo tee -a /etc/NetworkManager/conf.d/rke2-canal.conf > /dev/null cat <<EOT\n[keyfile]\nunmanaged-devices=interface-name:cali*;interface-name:flannel*\nEOT\n\n#\n# Big-bang specific tuning\n#\n\n# Configure aws cli default region to current region, it'd be great if the aws cli did this on install........\naws configure set default.region $(curl -s http://169.254.169.254/latest/meta-data/placement/region)\n\n# Tune vm sysctl for elasticsearch\nsysctl -w vm.max_map_count=524288\n\n# SonarQube host pre-requisites\nsysctl -w fs.file-max=131072\nulimit -n 131072\nulimit -u 8192\n\n# Preload kernel modules required by istio-init, required for selinux enforcing instances using istio-init\nmodprobe xt_REDIRECT\nmodprobe xt_owner\nmodprobe xt_statistic\n# Persist modules after reboots\nprintf \"xt_REDIRECT\\nxt_owner\\nxt_statistic\\n\" | sudo tee -a /etc/modules\n"` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR of the VPC | `string` | `"10.0.0.0/16"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bastion_public_ip_address"></a> [bastion\_public\_ip\_address](#output\_bastion\_public\_ip\_address) | Public IP address of bastion host |
| <a name="output_bastion_username"></a> [bastion\_username](#output\_bastion\_username) | Usernae of the SSH user on the bastion host |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the RKE2 cluster |
| <a name="output_kubeconfig_s3_path"></a> [kubeconfig\_s3\_path](#output\_kubeconfig\_s3\_path) | S3 path to the cluster's kubeconfig file |
| <a name="output_kubernetes_api_server_url"></a> [kubernetes\_api\_server\_url](#output\_kubernetes\_api\_server\_url) | URL to the Kubernetes API server |
| <a name="output_kubernetes_version"></a> [kubernetes\_version](#output\_kubernetes\_version) | Kubernetes version of the RKE2 cluster |
| <a name="output_private_ssh_key"></a> [private\_ssh\_key](#output\_private\_ssh\_key) | SSH private key to bastion and agent nodes in PEM format |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Update Terraform content

1. Prepare the tarball of the module with:

   ```bash
   tar -zcvf /tmp/module.tgz .
   ```

1. Set environmental variables:
   ```bash
   export BUCKET="capactio-terraform-modules"
   export MANIFEST_PATH="terraform.aws.containerization.rke2.deploy"
   export MANIFEST_REVISION="0.1.0"
   ```

1. Upload `tgz` directory to GCS bucket:

   ```bash
   gsutil cp /tmp/module.tgz gs://${BUCKET}/${MANIFEST_PATH}/${MANIFEST_REVISION}/module.tgz
   ```
