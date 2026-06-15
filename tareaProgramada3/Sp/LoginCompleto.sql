USE [tareaProgramada3]
GO

/****** Object:  StoredProcedure [dbo].[loginCompleto]    Script Date: 15/06/2026 11:01:16 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[loginCompleto]
    @Username VARCHAR(50),
    @Password VARCHAR(50),
    @IP VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @Intentos INT
        DECLARE @Id INT
        DECLARE @PassBD VARCHAR(50)
        DECLARE @TipoUsuario VARCHAR(100)
        
        -- 1. VERIFICAR BLOQUEO
        
        SELECT @Intentos = COUNT(*)
        FROM BitacoraEvento
        WHERE IdTipoEvento = 2
          AND PostInIP = @IP
          AND PostTime >= DATEADD(MINUTE, -20, GETDATE())

        IF (@Intentos >= 5)
        BEGIN
            IF EXISTS (
                SELECT 1
                FROM BitacoraEvento
                WHERE IdTipoEvento = 3
                  AND PostInIP = @IP
                  AND PostTime >= DATEADD(MINUTE, -10, GETDATE())
            )
            BEGIN
                SELECT 1 AS Bloqueado
                RETURN
            END

            SELECT 1 AS Bloqueado
            RETURN
        END

        -- 2. CONSULTAR USUARIO (CON TRANSACCIÓN)

        BEGIN TRANSACTION

            SELECT @Id = id, @PassBD = pwd, @TipoUsuario = TipoUsuario
            FROM Usuario
            WHERE username = @Username

            IF @Id IS NULL
            BEGIN
                ROLLBACK;
                SELECT 50001 AS Resultado
                RETURN
            END

            IF @PassBD <> @Password
            BEGIN
                ROLLBACK;
                SELECT 50002 AS Resultado
                RETURN
            END

        COMMIT;

        
        -- 3. LOGIN EXITOSO
       
        SELECT 0 AS Resultado,
               @Id AS IdUsuario,
               @Username AS Username,
               @TipoUsuario AS Tipo

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;

        SELECT 50008 AS Resultado
    END CATCH
END
GO


