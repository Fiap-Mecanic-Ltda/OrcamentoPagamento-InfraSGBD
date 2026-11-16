variable "aws_region" {
  type    = string
  default = "us-east-1"
}

# project_name e environment precisam bater com os do InfraKubernete do monolito.
variable "project_name" {
  type    = string
  default = "mechanicltda"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "service_name" {
  type        = string
  description = "Nome curto do microsservico. Compoe nomes de recursos e o prefixo do SSM."
  default     = "orcamento"
}

# Rede: vem do InfraKubernete do monolito, lido via terraform_remote_state (data.tf).

variable "kubernetes_state_bucket" {
  type        = string
  description = "Bucket S3 com o state do InfraKubernete do monolito."
  default     = "mechanicltda-terraform-state-788516091173"
}

variable "kubernetes_state_key" {
  type        = string
  description = "Chave do state do InfraKubernete do monolito dentro do bucket."
  default     = "prod/terraform.tfstate"
}

# RDS

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_engine_version" {
  type        = string
  description = "Versao do engine SQL Server Express (sqlserver-ex)."
  default     = "15.00.4430.1.v1"
}

variable "db_master_username" {
  type        = string
  description = "Usuario master do RDS. Nao pode ser 'sa'."
  default     = "orcamento_admin"
}

variable "db_master_password" {
  type        = string
  description = "Senha do usuario master. Regras do RDS: 8-128 chars, sem / @ \" e sem espaco."
  sensitive   = true
}

variable "db_name" {
  type        = string
  description = "Banco do servico na connection string publicada no SSM."
  default     = "MechanicOrcamentoDb"
}

variable "db_allocated_storage" {
  type        = number
  description = "Storage do RDS em GiB (minimo do SQL Server Express: 20)."
  default     = 20
}

variable "db_backup_retention_period" {
  type    = number
  default = 7
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Destroi o RDS sem snapshot final. true = perda definitiva dos dados."
  default     = false
}

variable "final_snapshot_identifier" {
  type        = string
  description = "Nome do snapshot final criado no destroy do RDS."
  default     = "mechanicltda-prod-orcamento-final"
}
