locals {
  name = "bigbang-${var.namespace}"

  tags = {
    "project"   = "platform-one"
    "namespace" = var.namespace
    "terraform" = "true"
  }

  registries_setup_script = var.registries_config == "" ? "" : <<EOF
sudo mkdir -p /etc/rancher/rke2
sudo tee -a /etc/rancher/rke2/registries.yaml > /dev/null cat <<EOT
${var.registries_config}
EOT
EOF

  user_data = join("\n", [local.registries_setup_script, var.user_data])
}
