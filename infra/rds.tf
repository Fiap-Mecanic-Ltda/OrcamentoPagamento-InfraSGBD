# Banco proprio do microsservico (ADR-001 do OrcamentoPagamento-service):
# instancia RDS separada da do monolito, nas mesmas subnets privadas.

resource "aws_db_subnet_group" "orcamento" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = local.db_subnet_ids

  tags = {
    Name = "${local.name_prefix}-db-subnet-group"
  }
}

resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-sg"
  description = "SG do RDS do orcamento, so aceita trafego dos nos k3s"
  vpc_id      = local.vpc_id

  # Server e workers: o pod da API pode ser agendado em qualquer no.
  ingress {
    description     = "SQL Server dos nos k3s (server + workers)"
    from_port       = 1433
    to_port         = 1433
    protocol        = "tcp"
    security_groups = local.k3s_node_sgids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-rds-sg"
  }
}

resource "aws_db_instance" "orcamento" {
  identifier     = local.name_prefix
  engine         = "sqlserver-ex"
  engine_version = var.db_engine_version
  license_model  = "license-included"

  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  # SQL Server no RDS nao aceita db_name na criacao: o banco MechanicOrcamentoDb
  # e criado pelas migrations do EF Core na primeira subida da API.
  username = var.db_master_username
  password = var.db_master_password

  db_subnet_group_name   = aws_db_subnet_group.orcamento.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az            = false
  publicly_accessible = false

  backup_retention_period    = var.db_backup_retention_period
  auto_minor_version_upgrade = true
  copy_tags_to_snapshot      = true

  # Sem protecao contra exclusao (projeto de estudo), mas com snapshot final por
  # padrao. Para descartar os dados de vez: -var="skip_final_snapshot=true".
  deletion_protection = false

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : var.final_snapshot_identifier

  tags = {
    Name = "${local.name_prefix}-sqlserver"
  }
}
