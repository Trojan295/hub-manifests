locals {
  private_ssh_key_dir      = "/tmp"
  private_ssh_key_name     = "${local.name}-keypair"
  private_ssh_key_filepath = "${local.private_ssh_key_dir}/${local.private_ssh_key_name}.pem"
}

module "ssh" {
  source = "git::https://repo1.dso.mil/platform-one/big-bang/customers/template.git//terraform/modules/ssh?ref=1.1.1"

  name             = local.private_ssh_key_name
  private_key_path = local.private_ssh_key_dir
}

data "local_file" "private_ssh_key" {
  depends_on = [
    module.ssh
  ]

  filename = local.private_ssh_key_filepath
}
