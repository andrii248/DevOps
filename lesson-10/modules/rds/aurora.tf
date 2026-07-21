resource "aws_rds_cluster" "this" {
  count = var.use_aurora ? 1 : 0

  cluster_identifier = "${var.name}-cluster"

  engine         = local.effective_aurora_engine
  engine_version = local.effective_engine_version
  engine_mode    = "provisioned"

  database_name   = var.db_name
  master_username = var.db_username
  port            = local.database_port

  manage_master_user_password = var.manage_master_user_password
  master_password             = var.manage_master_user_password ? null : var.db_password

  db_subnet_group_name = aws_db_subnet_group.this.name
  vpc_security_group_ids = [
    aws_security_group.this.id
  ]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this[0].name

  storage_encrypted         = var.storage_encrypted
  kms_key_id                = var.kms_key_id
  backup_retention_period   = var.backup_retention_period
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name}-final-cluster-snapshot"
  apply_immediately         = var.apply_immediately
  copy_tags_to_snapshot     = true

  tags = merge(local.common_tags, {
    Name = "${var.name}-cluster"
    Type = "aurora-cluster"
  })

  lifecycle {
    precondition {
      condition     = var.manage_master_user_password || var.db_password != null
      error_message = "db_password must be provided when manage_master_user_password is false."
    }
  }
}

resource "aws_rds_cluster_instance" "writer" {
  count = var.use_aurora ? 1 : 0

  identifier         = "${var.name}-writer"
  cluster_identifier = aws_rds_cluster.this[0].id

  engine         = aws_rds_cluster.this[0].engine
  engine_version = aws_rds_cluster.this[0].engine_version
  instance_class = var.instance_class
  promotion_tier = 0

  db_subnet_group_name = aws_db_subnet_group.this.name
  publicly_accessible  = var.publicly_accessible

  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.apply_immediately

  tags = merge(local.common_tags, {
    Name = "${var.name}-writer"
    Role = "writer"
  })
}

resource "aws_rds_cluster_instance" "readers" {
  count = var.use_aurora ? var.aurora_replica_count : 0

  identifier         = "${var.name}-reader-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.this[0].id

  engine         = aws_rds_cluster.this[0].engine
  engine_version = aws_rds_cluster.this[0].engine_version
  instance_class = var.instance_class
  promotion_tier = count.index + 1

  db_subnet_group_name = aws_db_subnet_group.this.name
  publicly_accessible  = var.publicly_accessible

  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.apply_immediately

  tags = merge(local.common_tags, {
    Name = "${var.name}-reader-${count.index + 1}"
    Role = "reader"
  })
}
