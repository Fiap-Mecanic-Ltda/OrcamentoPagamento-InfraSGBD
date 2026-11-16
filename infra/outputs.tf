output "rds_endpoint" {
  value = aws_db_instance.orcamento.endpoint
}

output "rds_address" {
  value = aws_db_instance.orcamento.address
}

output "rds_port" {
  value = aws_db_instance.orcamento.port
}

output "rds_security_group_id" {
  value = aws_security_group.rds.id
}

output "db_connection_ssm_parameter" {
  description = "Nome do parametro SSM com a connection string (SecureString)."
  value       = aws_ssm_parameter.db_connection_string.name
}

output "ssm_path_prefix" {
  value = local.ssm_path_prefix
}
