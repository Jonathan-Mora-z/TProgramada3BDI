USE [tareaProgramada3]
GO

/****** Object:  StoredProcedure [dbo].[InsertarUsuario]    Script Date: 18/06/2026 12:45:39 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertarUsuario]
    @Id INT,
    @Username VARCHAR(100),
    @Pwd VARCHAR(100),
    @TipoUsuario INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        BEGIN TRANSACTION

        IF (@Username IS NULL OR @Username = '')
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        IF (@Pwd IS NULL OR @Pwd = '')
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        IF (@TipoUsuario NOT IN (1,2))
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        IF EXISTS
        (
            SELECT 1
            FROM Usuario
            WHERE Id = @Id
        )
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        IF EXISTS
        (
            SELECT 1
            FROM Usuario
            WHERE Username = @Username
        )
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        INSERT INTO Usuario
        (
            Id,
            Username,
            Pwd,
            TipoUsuario
        )
        VALUES
        (
            @Id,
            @Username,
            @Pwd,
            @TipoUsuario
        );

        COMMIT;

        SELECT 0 AS Resultado;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK;

        INSERT INTO DBError
        (
            UserName,
            Number,
            Estado,
            Severity,
            Line,
            Procedimiento,
            Mensaje,
            Fecha
        )
        VALUES
        (
            SYSTEM_USER,
            ERROR_NUMBER(),
            ERROR_STATE(),
            ERROR_SEVERITY(),
            ERROR_LINE(),
            ERROR_PROCEDURE(),
            ERROR_MESSAGE(),
            GETDATE()
        );

        SELECT 50008 AS Resultado;

    END CATCH
END
GO


