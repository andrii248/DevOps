locals {
  normalized_rds_engine = lower(var.engine)

  effective_aurora_engine = var.engine_cluster != null ? lower(var.engine_cluster) : (
    local.normalized_rds_engine == "mysql" ? "aurora-mysql" : "aurora-postgresql"
  )

  effective_engine = var.use_aurora ? local.effective_aurora_engine : local.normalized_rds_engine

  effective_engine_version = var.use_aurora ? coalesce(
    var.engine_version_cluster,
    var.engine_version
  ) : var.engine_version

  is_postgresql = contains([
    "postgres",
    "aurora-postgresql"
  ], local.effective_engine)

  database_port = var.port != null ? var.port : (local.is_postgresql ? 5432 : 3306)

  rds_version_parts    = split(".", var.engine_version)
  aurora_version_parts = split(".", coalesce(var.engine_version_cluster, var.engine_version))

  rds_family_version = local.normalized_rds_engine == "postgres" ? (
    local.rds_version_parts[0]
    ) : (
    join(".", slice(local.rds_version_parts, 0, 2))
  )

  aurora_family_version = local.effective_aurora_engine == "aurora-postgresql" ? (
    local.aurora_version_parts[0]
    ) : (
    join(".", slice(local.aurora_version_parts, 0, 2))
  )

  derived_parameter_group_family_rds = local.normalized_rds_engine == "postgres" ? (
    "postgres${local.rds_family_version}"
    ) : (
    "mysql${local.rds_family_version}"
  )

  derived_parameter_group_family_aurora = local.effective_aurora_engine == "aurora-postgresql" ? (
    "aurora-postgresql${local.aurora_family_version}"
    ) : (
    "aurora-mysql${local.aurora_family_version}"
  )

  effective_parameter_group_family = var.use_aurora ? coalesce(
    var.parameter_group_family_aurora,
    local.derived_parameter_group_family_aurora
    ) : coalesce(
    var.parameter_group_family_rds,
    local.derived_parameter_group_family_rds
  )

  postgres_default_parameters = {
    max_connections = "200"
    log_statement   = "ddl"
    work_mem        = "4096"
  }

  mysql_default_parameters = {
    max_connections = "200"
    general_log     = "0"
    slow_query_log  = "1"
  }

  effective_parameters = var.parameters != null ? var.parameters : (
    local.is_postgresql ? local.postgres_default_parameters : local.mysql_default_parameters
  )

  effective_subnet_ids = var.publicly_accessible ? var.subnet_public_ids : var.subnet_private_ids

  common_tags = merge(
    {
      Name      = var.name
      ManagedBy = "Terraform"
      Module    = "rds"
    },
    var.tags
  )
}

resource "aws_db_subnet_group" "this" {
  name        = "${var.name}-subnet-group"
  description = "Database subnet group for ${var.name}"
  subnet_ids  = local.effective_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.name}-subnet-group"
  })

  lifecycle {
    precondition {
      condition     = length(local.effective_subnet_ids) >= 2
      error_message = "The selected DB subnet group must contain at least two subnets. Provide subnet_public_ids when publicly_accessible is true."
    }
  }
}

resource "aws_security_group" "this" {
  name_prefix = "${var.name}-db-"
  description = "Database access for ${var.name}"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = length(var.allowed_cidr_blocks) > 0 ? [1] : []

    content {
      description = "Database access from trusted CIDR blocks"
      from_port   = local.database_port
      to_port     = local.database_port
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidr_blocks
    }
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.name}-db-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_parameter_group" "this" {
  count = var.use_aurora ? 0 : 1

  name        = "${var.name}-rds-params"
  family      = local.effective_parameter_group_family
  description = "Parameter group for ${var.name} standard RDS instance"

  dynamic "parameter" {
    for_each = local.effective_parameters

    content {
      name         = parameter.key
      value        = parameter.value
      apply_method = "pending-reboot"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.name}-rds-params"
  })
}

resource "aws_rds_cluster_parameter_group" "this" {
  count = var.use_aurora ? 1 : 0

  name        = "${var.name}-aurora-params"
  family      = local.effective_parameter_group_family
  description = "Cluster parameter group for ${var.name} Aurora cluster"

  dynamic "parameter" {
    for_each = local.effective_parameters

    content {
      name         = parameter.key
      value        = parameter.value
      apply_method = "pending-reboot"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.name}-aurora-params"
  })
}
