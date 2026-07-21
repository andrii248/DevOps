# Reusable Terraform RDS / Aurora Module

This project extends the previous homework with a reusable `modules/rds` module. The same module can create either a standard Amazon RDS instance or an Amazon Aurora cluster, depending on the value of `use_aurora`.

```hcl
use_aurora = false # one aws_db_instance
use_aurora = true  # Aurora cluster + writer + optional readers
```

## Implemented functionality

The module always creates:

- `aws_db_subnet_group`;
- `aws_security_group`;
- `aws_db_parameter_group` for standard RDS or `aws_rds_cluster_parameter_group` for Aurora;
- basic PostgreSQL parameters: `max_connections`, `log_statement`, and `work_mem`.

Only one database scenario is created, depending on `use_aurora`:

```text
use_aurora = false
└── aws_db_instance

use_aurora = true
├── aws_rds_cluster
├── aws_rds_cluster_instance.writer
└── aws_rds_cluster_instance.readers[0..N]  # optional
```

For MySQL, the module uses a compatible default parameter set because `log_statement` and `work_mem` are PostgreSQL-specific parameters. A custom set can be supplied through `parameters`.

## Module structure

```text
modules/rds/
├── rds.tf       # standard aws_db_instance
├── aurora.tf    # Aurora cluster, writer, and optional readers
├── shared.tf    # subnet group, security group, parameter groups, and locals
├── variables.tf # typed variables, descriptions, defaults, and validations
└── outputs.tf   # endpoint, reader endpoint, security group, subnet group, etc.
```

## Module usage example

```hcl
module "rds" {
  source = "./modules/rds"

  name       = "myapp-db"
  use_aurora = false
  vpc_id     = module.vpc.vpc_id

  subnet_private_ids  = module.vpc.private_subnet_ids
  subnet_public_ids   = module.vpc.public_subnet_ids
  publicly_accessible = false
  allowed_cidr_blocks = ["10.0.0.0/16"]

  engine         = "postgres"
  engine_version = "16.4"
  instance_class = "db.t4g.medium"
  multi_az       = true

  db_name     = "myapp"
  db_username = "dbadmin"

  manage_master_user_password = true

  tags = {
    Environment = "dev"
    Project     = "myapp"
  }
}
```

## Standard RDS

```hcl
use_aurora     = false
engine         = "postgres"
engine_version = "16.4"
instance_class = "db.t4g.medium"
multi_az       = true
```

This mode creates one `aws_db_instance`. The `multi_az` variable controls whether a standby instance is created in another Availability Zone.

## Aurora PostgreSQL

For the minimum switch, only change:

```hcl
use_aurora = true
```

The module automatically converts `postgres` to `aurora-postgresql` and uses `engine_version` as the Aurora version.

When the available Aurora version differs from the standard RDS version, Aurora-specific values can be provided explicitly:

```hcl
use_aurora                    = true
engine                        = "postgres"
engine_version                = "16.4"
engine_cluster                = "aurora-postgresql"
engine_version_cluster        = "16.4"
parameter_group_family_aurora = "aurora-postgresql16"
aurora_replica_count          = 1
```

`aurora_replica_count = 1` means one writer plus one reader. A value of `0` creates only the required writer, as specified in the main assignment requirements.

## MySQL / Aurora MySQL

Standard MySQL:

```hcl
use_aurora     = false
engine         = "mysql"
engine_version = "8.0.40"
```

Aurora MySQL with explicit overrides:

```hcl
use_aurora                    = true
engine                        = "mysql"
engine_version                = "8.0.40"
engine_cluster                = "aurora-mysql"
engine_version_cluster        = "8.0.40"
parameter_group_family_aurora = "aurora-mysql8.0"
```

Before running `terraform apply`, verify that the selected engine version and instance class are available in the chosen AWS Region.

## Parameter Group

By default, the module creates the following PostgreSQL parameters:

```hcl
parameters = {
  max_connections = "200"
  log_statement   = "ddl"
  work_mem        = "4096"
}
```

Custom parameters can be supplied as a map:

```hcl
parameters = {
  max_connections            = "250"
  log_statement              = "all"
  work_mem                   = "8192"
  log_min_duration_statement = "500"
}
```

Changes are configured with `apply_method = "pending-reboot"`.

## Networking and security

By default, the database is placed in private subnets:

```hcl
publicly_accessible = false
subnet_private_ids  = module.vpc.private_subnet_ids
```

For a public training scenario:

```hcl
publicly_accessible = true
subnet_public_ids   = module.vpc.public_subnet_ids
```

The Security Group opens only the port used by the selected engine for CIDR blocks listed in `allowed_cidr_blocks`. In the root example, access is allowed only from the current VPC CIDR instead of `0.0.0.0/0`.

## Master password

The secure default option is:

```hcl
manage_master_user_password = true
```

AWS generates the master password and stores it in AWS Secrets Manager. The secret ARN is available through a sensitive output.

To provide a password manually:

```hcl
manage_master_user_password = false
```

Pass the password outside Git:

```bash
export TF_VAR_db_password='REPLACE_WITH_A_STRONG_PASSWORD'
```

## Module variables

| Variable                        | Type           |          Default | Description                                                     |
| ------------------------------- | -------------- | ---------------: | --------------------------------------------------------------- |
| `name`                          | `string`       | `application-db` | Resource name prefix.                                           |
| `use_aurora`                    | `bool`         |          `false` | `true` creates Aurora; `false` creates standard RDS.            |
| `vpc_id`                        | `string`       |         required | VPC used by the database Security Group.                        |
| `subnet_private_ids`            | `list(string)` |         required | Private subnets for the DB Subnet Group.                        |
| `subnet_public_ids`             | `list(string)` |             `[]` | Public subnets used when `publicly_accessible = true`.          |
| `allowed_cidr_blocks`           | `list(string)` |             `[]` | CIDR blocks allowed to connect to the database.                 |
| `engine`                        | `string`       |       `postgres` | Standard RDS engine: `postgres` or `mysql`.                     |
| `engine_version`                | `string`       |           `16.4` | Standard RDS version and fallback Aurora version.               |
| `engine_cluster`                | `string`       |           `null` | Optional `aurora-postgresql` or `aurora-mysql` override.        |
| `engine_version_cluster`        | `string`       |           `null` | Optional Aurora-specific engine version.                        |
| `parameter_group_family_rds`    | `string`       |           `null` | Explicit RDS parameter group family or automatic derivation.    |
| `parameter_group_family_aurora` | `string`       |           `null` | Explicit Aurora parameter group family or automatic derivation. |
| `instance_class`                | `string`       |  `db.t4g.medium` | RDS or Aurora instance class.                                   |
| `aurora_replica_count`          | `number`       |              `0` | Number of Aurora readers in addition to the writer.             |
| `multi_az`                      | `bool`         |          `false` | Enables Multi-AZ for standard RDS.                              |
| `db_name`                       | `string`       |    `application` | Initial database name.                                          |
| `db_username`                   | `string`       |        `dbadmin` | Master username.                                                |
| `manage_master_user_password`   | `bool`         |           `true` | Manages the password through AWS Secrets Manager.               |
| `db_password`                   | `string`       |           `null` | Manual sensitive password.                                      |
| `port`                          | `number`       |           `null` | Automatic default: 5432 for PostgreSQL, 3306 for MySQL.         |
| `parameters`                    | `map(string)`  |           `null` | Custom database parameter map.                                  |
| `allocated_storage`             | `number`       |             `20` | Initial standard RDS storage in GiB.                            |
| `max_allocated_storage`         | `number`       |            `100` | RDS storage autoscaling limit; `0` disables autoscaling.        |
| `storage_type`                  | `string`       |            `gp3` | Standard RDS storage type.                                      |
| `storage_encrypted`             | `bool`         |           `true` | Enables storage encryption.                                     |
| `kms_key_id`                    | `string`       |           `null` | Optional KMS key ARN or ID.                                     |
| `backup_retention_period`       | `number`       |              `7` | Number of days to retain automated backups.                     |
| `publicly_accessible`           | `bool`         |          `false` | Enables a public endpoint and selects public subnets.           |
| `deletion_protection`           | `bool`         |          `false` | Protects the database from accidental deletion.                 |
| `skip_final_snapshot`           | `bool`         |           `true` | Skips the final snapshot in this training project.              |
| `apply_immediately`             | `bool`         |          `false` | Applies modifications immediately.                              |
| `auto_minor_version_upgrade`    | `bool`         |           `true` | Enables automatic minor version upgrades.                       |
| `tags`                          | `map(string)`  |             `{}` | Additional resource tags.                                       |

## Root variables for quick configuration changes

```hcl
use_aurora                       = false
db_engine                        = "postgres"
db_engine_version                = "16.4"
db_engine_cluster                = null
db_engine_version_cluster        = null
db_parameter_group_family_rds    = null
db_parameter_group_family_aurora = null
db_instance_class                = "db.t4g.medium"
db_aurora_replica_count          = 0
db_multi_az                      = false
db_publicly_accessible           = false
```

When the Aurora engine or parameter group family is `null`, the module derives it automatically. This keeps switching through `use_aurora` simple while still allowing explicit overrides when AWS supports a different Aurora version.

## Outputs

The module returns:

- selected mode: `rds` or `aurora`;
- effective engine and engine version;
- writer endpoint;
- Aurora reader endpoint;
- Aurora reader instance identifiers;
- database port;
- DB Subnet Group name;
- Security Group ID;
- Parameter Group name;
- ARN of the secret containing the master password.

## Running and validating the project

The local folder may be named `lesson-10`. Run all commands from the directory containing `main.tf`, `backend.tf`, and the `modules/` directory.

### 1. Prepare local variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

For `terraform plan`, `github_token = "REPLACE_ME"` is sufficient because Terraform does not verify GitHub authentication while generating the plan.

A real GitHub Personal Access Token is required only for `terraform apply` and actual Jenkins operation. Do not commit it. For a real deployment, either replace the value locally in `terraform.tfvars`, or remove the `github_token` line from that file and pass the token through Git Bash:

```bash
export TF_VAR_github_token='github_pat_YOUR_REAL_TOKEN'
```

### 2. Format, initialize, and validate

```bash
terraform fmt -recursive
terraform init -reconfigure
terraform validate
```

Expected validation result:

```text
Success! The configuration is valid.
```

### 3. Validate standard RDS mode

The default value in `terraform.tfvars` is:

```hcl
use_aurora = false
```

Generate the plan:

```bash
terraform plan
```

The RDS module section of the plan should contain:

```text
module.rds.aws_db_instance.this[0]
module.rds.aws_db_parameter_group.this[0]
module.rds.aws_db_subnet_group.this
module.rds.aws_security_group.this
```

The `database_mode` output should be `rds`.

### 4. Validate Aurora mode

The second mode can be tested without editing files:

```bash
terraform plan -var="use_aurora=true"
```

The plan should contain:

```text
module.rds.aws_rds_cluster.this[0]
module.rds.aws_rds_cluster_instance.writer[0]
module.rds.aws_rds_cluster_parameter_group.this[0]
module.rds.aws_db_subnet_group.this
module.rds.aws_security_group.this
```

`module.rds.aws_db_instance.this[0]` must not be created in this mode, and the `database_mode` output should be `aurora`.

To add one reader in addition to the required writer:

```bash
terraform plan -var="use_aurora=true" -var="db_aurora_replica_count=1"
```

The plan should additionally contain:

```text
module.rds.aws_rds_cluster_instance.readers[0]
```

The root project also includes VPC, EKS, ECR, Jenkins, and Argo CD resources from previous lessons. Therefore, the complete plan also displays those resources. For this homework, focus primarily on entries beginning with `module.rds.`.

`terraform plan` does not create AWS resources. Run `terraform apply` only when you intentionally want to deploy the infrastructure and have considered the cost of EKS, NAT Gateway, RDS or Aurora, and other AWS services.

## Local validation results

Both modes were successfully checked with `terraform validate` and `terraform plan`:

```text
use_aurora = false → standard PostgreSQL RDS instance
use_aurora = true  → Aurora PostgreSQL cluster + writer
```

The plans confirmed creation of the DB Subnet Group, Security Group, and the correct Parameter Group containing `max_connections`, `log_statement`, and `work_mem`.
