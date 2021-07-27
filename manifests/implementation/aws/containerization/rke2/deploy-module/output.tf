output "cluster_name" {
  value       = local.name
  description = "Name of the RKE2 cluster"
}

output "kubeconfig_s3_path" {
  value       = module.server.kubeconfig_path
  description = "S3 path to the cluster's kubeconfig file"
}

output "kubernetes_version" {
  value       = var.rke2_version
  description = "Kubernetes version of the RKE2 cluster"
}

output "kubernetes_api_server_url" {
  value       = "https://${module.server.server_url}:6443"
  description = "URL to the Kubernetes API server"
}

output "private_ssh_key" {
  value       = base64encode(data.local_file.private_ssh_key.content)
  description = "SSH private key to bastion and agent nodes in PEM format"
}

output "bastion_public_ip_address" {
  value       = module.bastion.public_ip
  description = "Public IP address of bastion host"
}

output "bastion_username" {
  value       = module.bastion.ssh_user
  description = "Usernae of the SSH user on the bastion host"
}
