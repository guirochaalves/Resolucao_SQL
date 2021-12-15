/* 
  Conhecimento de SQL Server
  Obs: Não sei de onde é essa prova ou exercício. 
       Peguei na net para testar conhecimento
*/

-- Conhecimentos SQL e T-SQL

-- 1. Criar script de criação do modelo de dados acima. 

CREATE TABLE CLIENTE (
	ID			INT NOT NULL,
	NOME		VARCHAR(45) NOT NULL,
	TELEFONE	VARCHAR(45) NOT NULL,
	EMAIL		VARCHAR(100)NOT NULL,
	PRIMARY KEY(ID)
);
GO
 
CREATE TABLE VENDEDOR (
	ID INT NOT NULL,
	NOME VARCHAR(45),
	PRIMARY KEY (ID)
);
GO

CREATE TABLE PAGAMENTO (
	ID				INT NOT NULL,
	FORMA_PAGAMENTO VARCHAR(45),
	PRIMARY KEY (ID)
);
 
CREATE TABLE VENDA (
	ID				INT NOT NULL, 
	VALOR_TOTAL		DECIMAL(10,2),
	DATA			DATETIME, 
	CLIENTE_ID		INT NOT NULL,
	VENDEDOR_ID		INT NOT NULL,
	PAGAMENTO_ID	INT NOT NULL,
	PRIMARY KEY(ID)
);

CREATE TABLE VENDA_HAS_PRODUTO (
	VENDA_ID	INT NOT NULL, 
	PRODUTO_ID	INT NOT NULL
);
GO

CREATE TABLE PRODUTO (
	ID				INT NOT NULL, 
	NOME			VARCHAR(45),
	PREÇO			DECIMAL(10,2),
	QTD_ESTOQUE		VARCHAR(45),
	CATEGORIA_ID	INT NOT NULL,
	FORNECEDORES_ID	INT NOT NULL,
	PRIMARY KEY (ID)
);
 
CREATE TABLE CATEGORIA (
	ID		INT NOT NULL,
	NOME	VARCHAR(45),
	PRIMARY KEY (ID)
);
GO
 
CREATE TABLE FORNECEDORES (
	ID		INT NOT NULL,
	CNPJ	VARCHAR(45),
	NOME	VARCHAR(45),
	PRIMARY KEY (ID)
);
GO

ALTER TABLE VENDA 
ADD CONSTRAINT FK_CLIENTE_ID FOREIGN KEY (CLIENTE_ID) REFERENCES CLIENTE (ID);
GO

ALTER TABLE VENDA
ADD CONSTRAINT FK_VENDEDOR_ID FOREIGN KEY (VENDEDOR_ID) REFERENCES VENDEDOR (ID);
GO

ALTER TABLE VENDA
ADD CONSTRAINT FK_PAGAMENTO_ID FOREIGN KEY (PAGAMENTO_ID) REFERENCES PAGAMENTO (ID);
GO

ALTER TABLE VENDA_HAS_PRODUTO
ADD CONSTRAINT FK_VENDA_HAS_VENDA_ID FOREIGN KEY (VENDA_ID) REFERENCES VENDA (ID)
GO

ALTER TABLE VENDA_HAS_PRODUTO
ADD CONSTRAINT FK_VENDA_HAS_PRODUTO_ID FOREIGN KEY (PRODUTO_ID) REFERENCES PRODUTO (ID)
GO

ALTER TABLE PRODUTO
ADD CONSTRAINT FK_PRODUTO_CAT_ID FOREIGN KEY (CATEGORIA_ID) REFERENCES CATEGORIA (ID);
GO

ALTER TABLE PRODUTO
ADD CONSTRAINT FK_FORNECEDORES_ID FOREIGN KEY (FORNECEDORES_ID) REFERENCES FORNECEDORES (ID);
GO

-- 2.	Criar query para gerar relatório de todas as vendas do período de 01 de Janeiro até 01 de Agosto do ano corrente.

SELECT 	*
FROM 	VENDA
WHERE 	DATA >= DATEADD(YYYY, DATEDIFF(YYYY,0,GETDATE()), 0) AND DATA < DateAdd(mm, DateDiff(mm,0,getdate())-3,0)

-- 3.	Criar query para gerar relatório de todas as vendas consolidadas por vendedor.

SELECT	SUM(VALOR_TOTAL) AS TOTAL_VENDIDO, VE.NOME
FROM	VENDA AS V
JOIN	VENDEDOR AS VE ON V.VENDEDOR_ID = VE.ID
GROUP BY VE.NOME

-- 4.	Criar query para gerar relatório de todos os produtos vendidos por categoria e fornecedores.

SELECT	VALOR_TOTAL, CATEGORIA.NOME, FORNECEDORES.NOME
FROM	VENDA
JOIN	VENDA_HAS_PRODUTO AS VHP ON VENDA.ID = VHP.VENDA_ID
JOIN	PRODUTO ON PRODUTO.ID = VHP.PRODUTO_ID
JOIN	CATEGORIA ON PRODUTO.CATEGORIA_ID = CATEGORIA.ID
JOIN	FORNECEDORES ON FORNECEDORES.ID = PRODUTO.FORNECEDORES_ID
GROUP BY CATEGORIA.NOME, FORNECEDORES.NOME

-- 5.	Criar query para recuperar os 10 clientes que mais efetuaram compras.

SELECT TOP 10 WITH TIES SUM(VALOR_TOTAL) AS VALOR_GASTO_CLIENTE, CLIENTE.NOME
FROM	VENDA
JOIN	CLIENTE ON VENDA.CLIENTE_ID = CLIENTE.ID
GROUP BY CLIENTE.NOME
ORDER BY SUM(VALOR_TOTAL) DESC

-- 6.	Criar query para recuperar a forma de pagamento mais utilizada nas vendas.

SELECT TOP 1 WITH TIES COUNT(PAGAMENTO_ID), PAGAMENTO.FORMA_PAGAMENTO
FROM	VENDA
JOIN	PAGAMENTO ON VENDA.PAGAMENTO_ID = PAGAMENTO.ID
GROUP BY PAGAMENTO.FORMA_PAGAMENTO
ORDER BY COUNT(PAGAMENTO_ID) DESC

-- 7.	Criar procedure para cadastrar produtos.

CREATE PROCEDURE CADASTRAR_PRODUTO (
	@NOME VARCHAR(45), 
	@PRECO DECIMAL(10,2), 
	@QTDE_ESTOQUE VARCHAR(45), 
	@CAT_NOME VARCHAR(45), 
	@FORN_NOME VARCHAR(45)
)

AS

-- Definir variaveis
DECLARE @PROXIMO_VALOR INT
DECLARE @CAT_ID INT
DECLARE @FORN_ID INT

-- Pegar o próximo ID livre antes de inserir
SET @PROXIMO_VALOR = (SELECT TOP 1 ID + 1 FROM PRODUTO ORDER BY ID DESC)

BEGIN
	IF @NOME IS NULL OR @NOME ='' OR EXISTS (SELECT 1 FROM PRODUTO WHERE NOME = @NOME)
	BEGIN
		PRINT 'Nome não pode ficar vazio, nulo ou existir!'
		GOTO Final
	END

	IF @PRECO < 0 OR @PRECO IS NULL OR PRECO = ''
	BEGIN
		PRINT 'Preço não pode ser menor que zero ou vazio!'
		GOTO Final
	END

	IF @QTDE_ESTOQUE < 0 OR @QTDE_ESTOQUE IS NULL OR @QTDE_ESTOQUE = ''
	BEGIN
		PRINT 'Estoque não pode ser menor que zero, nulo ou vazio!'
		GOTO Final
	END

	IF NOT EXISTS (SELECT 1 FROM CATEGORIA WHERE NOME = @CAT_NOME) OR @CAT_NOME IS NULL OR @CAT_NOME = ''
		BEGIN
			PRINT 'Categoria inexistente, nula ou vazia! Favor conferir!'
			GOTO Final
		END
	ELSE
		BEGIN
			SELECT @CAT_ID = ID FROM dbo.CATEGORIA WHERE NOME = @CAT_NOME
		END

	IF	NOT EXISTS (SELECT 1 FROM dbo.FORNECEDORES WHERE NOME = @FORN_NOME) OR @FORN_NOME IS NULL OR @FORN_NOME=''
		BEGIN
			PRINT 'Fornecedor inexistente, vazio ou nulo! Favor conferir!'
			GOTO Final
		END
	ELSE
		BEGIN
			SELECT @FORN_ID = ID FROM dbo.FORNECEDORES WHERE NOME=@FORN_NOME
		END

	BEGIN TRY
		INSERT INTO PRODUTO (ID, NOME, PREÇO, QTD_ESTOQUE, CATEGORIA_ID, FORNECEDORES_ID) VALUES (@PROXIMO_VALOR, @NOME, @PRECO, @QTDE_ESTOQUE, @CAT_ID, @FORN_ID)
	END TRY
	BEGIN CATCH
		PRINT 'Erro ao inserir! Verificar os valores existentes!'
	END CATCH

	Final:
		RETURN

END

-- 8.	Criar função para recuperar as vendas por período.

CREATE FUNCTION [dbo].[RETORNAR_VENDAS_POR_PERIODO]
(
    @DATA_INICIAL DATETIME,
    @DATA_FINAL DATETIME
)
RETURNS TABLE AS RETURN

	SELECT	VENDA.VALOR_TOTAL, VENDA.DATA, CLIENTE.NOME AS NOME_CLIENTE, VENDEDOR.NOME AS NOME_VENDEDOR, PAGAMENTO.FORMA_PAGAMENTO
	FROM	VENDA
	JOIN	CLIENTE ON VENDA.CLIENTE_ID = CLIENTE.ID
	JOIN	VENDEDOR ON VENDA.VENDEDOR_ID = VENDEDOR.ID
	JOIN	PAGAMENTO ON VENDA.PAGAMENTO_ID = PAGAMENTO.ID
	WHERE	VENDA.DATA BETWEEN @DATA_INICIAL AND @DATA_FINAL;
