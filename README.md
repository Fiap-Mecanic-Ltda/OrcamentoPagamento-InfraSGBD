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
| Produção | RDS SQL Server via Terraform (`infra/`) | ⏳ próxima etapa |

## Estrutura

```
.
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

## Próximos passos

- **Terraform do RDS** em `infra/`, no mesmo molde do
  [InfraSGBD](https://github.com/Fiap-Mecanic-Ltda/InfraSGBD) do monólito: instância RDS SQL
  Server e connection string gravada no SSM Parameter Store, de onde a pipeline do
  InfraKubernete monta o Secret do Kubernetes.
- **Login de aplicação** com permissões mínimas, em vez de `sa`. Hoje a API usa `sa` porque
  aplica as migrations na subida e precisa de DDL; o caminho é um login `db_owner` só do
  `MechanicOrcamentoDb`.
