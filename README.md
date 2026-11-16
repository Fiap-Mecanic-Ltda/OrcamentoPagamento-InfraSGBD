# OrcamentoPagamento-InfraSGBD

Infraestrutura de banco de dados do microsserviço
[OrcamentoPagamento-service](https://github.com/Fiap-Mecanic-Ltda/OrcamentoPagamento-service).

O serviço tem **banco próprio** (`MechanicOrcamentoDb`), separado do banco do monólito. Este
repositório cuida da **instância e do banco**; o **schema** (tabelas, índices) continua sendo
das migrations do EF Core no serviço, aplicadas quando a API sobe.

| Ambiente | Onde o banco roda | Status |
|---|---|---|
| Local (Docker Compose) | Container `orcamento-sqlserver`, deste repositório | ✅ |
| Local (Kubernetes) | Pod `orcamento-sqlserver` do overlay `local` no [OrcamentoPagamento-InfraKubernete](https://github.com/Fiap-Mecanic-Ltda/OrcamentoPagamento-InfraKubernete) | ✅ |
| Produção | RDS SQL Server via Terraform (`infra/`) | ✅ |

## Estrutura

```
.
├── .github/workflows/
│   └── terraform.yml           # plan (homolog/PR) e apply manual (Environment production)
├── infra/                      # Terraform do RDS (state em s3://.../prod/orcamento/sgbd/terraform.tfstate)
│   ├── data.tf                 # VPC, subnets de banco e SGs dos nós, do InfraKubernete do monólito
│   ├── rds.tf                  # mechanicltda-prod-orcamento (sqlserver-ex), subnet group, SG
│   └── ssm.tf                  # /mechanicltda/prod/orcamento/db-connection-string
├── docker-compose.yml          # SQL Server 2022 + job de inicialização
├── .env.example                # SA_PASSWORD (copiar para .env)
└── scripts/
    └── init/
        └── 01-criar-banco.sql  # Cria o banco e liga READ_COMMITTED_SNAPSHOT (idempotente)
```

Os scripts de `scripts/init/` rodam em ordem alfabética a cada `docker compose up`, por isso
precisam ser idempotentes. Para adicionar outro passo (login de aplicação, por exemplo), crie
`02-...sql` no mesmo padrão.

## Subindo localmente

```bash
cp .env.example .env          # ajuste SA_PASSWORD
docker compose up -d
docker compose logs sqlserver-init   # deve terminar com "Criando o banco..." ou "já existe"
```

Isso cria:

- **SQL Server 2022** em `localhost:1434`. A porta `1433` fica livre para o banco do monólito.
- O banco **`MechanicOrcamentoDb`**.
- A rede Docker **`orcamento-net`**, que o compose do serviço usa para chegar ao banco pelo
  nome `orcamento-sqlserver`.

Depois disso, suba o serviço no repositório dele (`docker compose up --build`). Use o **mesmo
`SA_PASSWORD`** nos dois `.env`.

Conectar pelo host (SSMS, Azure Data Studio, sqlcmd):

```
Servidor: localhost,1434   Usuário: sa   Senha: <SA_PASSWORD>   Trust server certificate: sim
```

Derrubar:

```bash
docker compose down        # mantém os dados
docker compose down -v     # apaga o volume (banco zerado na próxima subida)
```

> Se o serviço ainda estiver de pé, `docker compose down` aqui não consegue remover a rede
> `orcamento-net`, que ainda está em uso. Derrube o serviço primeiro.

## Produção (Terraform)

Mesmo molde do [InfraSGBD](https://github.com/Fiap-Mecanic-Ltda/InfraSGBD) do monólito, mas
com **instância própria** (banco por serviço, ADR-001 do serviço):

- RDS SQL Server Express `mechanicltda-prod-orcamento` (`db.t3.micro`, 20 GiB gp3,
  criptografado, sem acesso público), nas subnets de banco do InfraKubernete.
- Security group aceitando a 1433 só dos nós do k3s (server e workers).
- Connection string em `/mechanicltda/prod/orcamento/db-connection-string` (SecureString),
  de onde o `deploy.yml` do
  [OrcamentoPagamento-InfraKubernete](https://github.com/Fiap-Mecanic-Ltda/OrcamentoPagamento-InfraKubernete)
  monta o Secret do Kubernetes.

O RDS de SQL Server não aceita criar o banco junto com a instância: o `MechanicOrcamentoDb`
nasce na primeira subida da API, pelas migrations do EF Core. Isso quer dizer que o
`READ_COMMITTED_SNAPSHOT` do `01-criar-banco.sql` **não** é aplicado em produção; se for
preciso, rode o script uma vez contra o RDS.

Pré-requisito: o InfraKubernete do monólito aplicado (este stack lê o state dele).

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars   # defina db_master_password
terraform init
terraform plan
terraform apply
```

No CI (`terraform.yml`), a senha vem do secret **`SA_PASSWORD`** e a AWS de
`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`. O apply é manual (`workflow_dispatch` →
`apply`) e passa pela aprovação do Environment `production`.

Depois de recriar o banco, rode o deploy do OrcamentoPagamento-InfraKubernete para a API
reler a connection string.

`terraform destroy` faz snapshot final por padrão. Para descartar os dados:
`terraform destroy -var="skip_final_snapshot=true"`.

## Próximos passos

- **Login de aplicação** com permissões mínimas, em vez de `sa`. Hoje a API usa `sa` porque
  aplica as migrations na subida e precisa de DDL; o caminho é um login `db_owner` só do
  `MechanicOrcamentoDb`.
