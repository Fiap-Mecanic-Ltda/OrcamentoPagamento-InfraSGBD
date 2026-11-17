-- Cria o banco do microsserviço OrcamentoPagamento, se ainda não existir.
-- Idempotente: pode rodar a cada subida do docker-compose.
--
-- Recebe o nome do banco pela variável sqlcmd DB_NOME (padrão MechanicOrcamentoDb).
-- Tabelas e índices NÃO são criados aqui: quem define o schema são as migrations do EF
-- Core do serviço, aplicadas na subida da API.

IF DB_ID(N'$(DB_NOME)') IS NULL
BEGIN
    PRINT N'Criando o banco $(DB_NOME)...';
    -- Collation padrão da instância, a mesma que o EF Core usava quando criava o banco
    -- sozinho. Trocar a collation muda comparação de texto (acento, maiúscula) e não é
    -- decisão de infra.
    CREATE DATABASE [$(DB_NOME)];
END
ELSE
    PRINT N'Banco $(DB_NOME) já existe. Nada a fazer.';
GO

-- READ_COMMITTED_SNAPSHOT evita que leituras (consultas de pagamento, PDF do orçamento)
-- fiquem bloqueadas pelas escritas do consumidor da fila e do webhook. É o padrão do
-- Azure SQL e o que o RDS deverá usar também.
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = N'$(DB_NOME)' AND is_read_committed_snapshot_on = 0)
BEGIN
    PRINT N'Ativando READ_COMMITTED_SNAPSHOT em $(DB_NOME)...';
    ALTER DATABASE [$(DB_NOME)] SET READ_COMMITTED_SNAPSHOT ON WITH ROLLBACK IMMEDIATE;
END
GO
