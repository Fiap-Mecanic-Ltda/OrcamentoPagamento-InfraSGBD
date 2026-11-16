# A connection string e o unico ponto de contato entre este stack e o servico:
# SecureString no SSM, lida pela pipeline de deploy do
# OrcamentoPagamento-InfraKubernete a cada rollout para montar o Secret.
locals {
  db_connection_string = "Server=${aws_db_instance.orcamento.address},1433;Database=${var.db_name};User Id=${var.db_master_username};Password=${var.db_master_password};TrustServerCertificate=True;"
}

resource "aws_ssm_parameter" "db_connection_string" {
  name  = "${local.ssm_path_prefix}/db-connection-string"
  type  = "SecureString"
  value = local.db_connection_string
}
