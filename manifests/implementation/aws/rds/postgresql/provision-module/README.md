# Source

This directory contains source Terraform module, which is used in the `cap.implementation.terraform.aws.rds.postgresql.provision:0.1.0` Implementation manifest.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.12.26 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 2.49 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 2.49 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_db"></a> [db](#module\_db) | terraform-aws-modules/rds/aws | ~> 2.35.0 |
| <a name="module_security_group"></a> [security\_group](#module\_security\_group) | terraform-aws-modules/security-group/aws | ~> 4.0.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | ~> 3.0.0 |

## Resources

| Name | Type |
|------|------|
| [random_string.name](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allocated_storage"></a> [allocated\_storage](#input\_allocated\_storage) | The allocated storage in gigabytes | `string` | `20` | no |
| <a name="input_backup_retention_period"></a> [backup\_retention\_period](#input\_backup\_retention\_period) | The days to retain backups for | `number` | `null` | no |
| <a name="input_backup_window"></a> [backup\_window](#input\_backup\_window) | The daily time range (in UTC) during which automated backups are created if they are enabled. Example: '09:46-10:16'. Must not overlap with maintenance\_window | `string` | `"03:00-06:00"` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | The database can't be deleted when this value is set to true. | `bool` | `false` | no |
| <a name="input_engine"></a> [engine](#input\_engine) | Database engine | `string` | `"postgres"` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | RDS database engine version | `string` | `"11.10"` | no |
| <a name="input_ingress_rule_cidr_blocks"></a> [ingress\_rule\_cidr\_blocks](#input\_ingress\_rule\_cidr\_blocks) | CIDR blocks for ingress rule. For public access provide '0.0.0.0/0'. | `string` | `""` | no |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | The window to perform maintenance in. Syntax: 'ddd:hh24:mi-ddd:hh24:mi'. Eg: 'Mon:00:00-Mon:03:00' | `string` | `"Mon:00:00-Mon:03:00"` | no |
| <a name="input_major_engine_version"></a> [major\_engine\_version](#input\_major\_engine\_version) | PostgreSQL major engine version | `string` | `"11"` | no |
| <a name="input_max_allocated_storage"></a> [max\_allocated\_storage](#input\_max\_allocated\_storage) | Specifies the value for Storage Autoscaling | `number` | `100` | no |
| <a name="input_monitoring_interval"></a> [monitoring\_interval](#input\_monitoring\_interval) | The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance. To disable collecting Enhanced Monitoring metrics, specify 0. The default is 0. Valid Values: 0, 1, 5, 10, 15, 30, 60. | `number` | `60` | no |
| <a name="input_multi_az"></a> [multi\_az](#input\_multi\_az) | Specifies if the RDS instance is multi-AZ | `bool` | `false` | no |
| <a name="input_performance_insights_enabled"></a> [performance\_insights\_enabled](#input\_performance\_insights\_enabled) | Specifies whether Performance Insights are enabled | `bool` | `false` | no |
| <a name="input_performance_insights_retention_period"></a> [performance\_insights\_retention\_period](#input\_performance\_insights\_retention\_period) | The amount of time in days to retain Performance Insights data. Either 7 (7 days) or 731 (2 years). | `number` | `7` | no |
| <a name="input_publicly_accessible"></a> [publicly\_accessible](#input\_publicly\_accessible) | Bool to control if instance is publicly accessible | `bool` | `false` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | n/a | yes |
| <a name="input_res_name"></a> [res\_name](#input\_res\_name) | Name used for the resources | `string` | `""` | no |
| <a name="input_skip_final_snapshot"></a> [skip\_final\_snapshot](#input\_skip\_final\_snapshot) | Determines whether a final DB snapshot is created before the DB instance is deleted. If true is specified, no DBSnapshot is created. If false is specified, a DB snapshot is created before the DB instance is deleted, using the value from final\_snapshot\_identifier | `bool` | `false` | no |
| <a name="input_storage_encrypted"></a> [storage\_encrypted](#input\_storage\_encrypted) | Specifies whether the DB instance is encrypted | `bool` | `true` | no |
| <a name="input_tier"></a> [tier](#input\_tier) | AWS RDS instance tier | `string` | `"db.t3.micro"` | no |
| <a name="input_user_name"></a> [user\_name](#input\_user\_name) | Database user name | `string` | n/a | yes |
| <a name="input_user_password"></a> [user\_password](#input\_user\_password) | Database user password | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_availability_zone"></a> [availability\_zone](#output\_availability\_zone) | Availability zones |
| <a name="output_class"></a> [class](#output\_class) | AWS RDS instance class |
| <a name="output_defaultDBName"></a> [defaultDBName](#output\_defaultDBName) | The master username for the database |
| <a name="output_identifier"></a> [identifier](#output\_identifier) | The AWS RDS instance identifier |
| <a name="output_instance_ip_addr"></a> [instance\_ip\_addr](#output\_instance\_ip\_addr) | The address of the RDS instance |
| <a name="output_password"></a> [password](#output\_password) | The database password |
| <a name="output_port"></a> [port](#output\_port) | The database port |
| <a name="output_username"></a> [username](#output\_username) | The master username for the database |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->


### Update Terraform content

1. Prepare `tgz` directory with the

   ```bash
   tar -zcvf /tmp/module.tgz . && cd -
   ```

1. Set environmental variables:
   ```bash
   export BUCKET="capactio-terraform-modules"
   export MANIFEST_PATH="terraform.aws.rds.postgresql.provision"
   export MANIFEST_REVISION="0.1.0"
   ```

1. Upload `tgz` directory to GCS bucket:

   ```bash
   gsutil cp /tmp/module.tgz gs://${BUCKET}/${MANIFEST_PATH}/${MANIFEST_REVISION}/module.tgz
   ```

