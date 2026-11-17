# A rede (VPC, subnets de banco) e os security groups dos nos k3s pertencem ao
# InfraKubernete do monolito - o servico roda no mesmo cluster. Este stack le os
# outputs do state remoto (so leitura, nao trava nem grava nada la).
data "terraform_remote_state" "kubernetes" {
  backend = "s3"

  config = {
    bucket = var.kubernetes_state_bucket
    key    = var.kubernetes_state_key
    region = var.aws_region
  }
}

locals {
  vpc_id        = data.terraform_remote_state.kubernetes.outputs.vpc_id
  db_subnet_ids = data.terraform_remote_state.kubernetes.outputs.db_subnet_ids
  k3s_node_sgids = [
    data.terraform_remote_state.kubernetes.outputs.ec2_security_group_id,
    data.terraform_remote_state.kubernetes.outputs.worker_security_group_id,
  ]

  name_prefix = "${var.project_name}-${var.environment}-${var.service_name}"

  # Subprefixo do prefixo do monolito: a pipeline de deploy ja tem leitura em
  # /projeto/ambiente/*.
  ssm_path_prefix = "/${var.project_name}/${var.environment}/${var.service_name}"
}
