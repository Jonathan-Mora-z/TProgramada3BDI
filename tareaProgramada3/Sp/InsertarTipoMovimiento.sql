USE [tareaProgramada3]
GO

/****** Object:  StoredProcedure [dbo].[InsertarTipoMovimiento]    Script Date: 15/06/2026 11:00:58 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertarTipoMovimiento]
    @Id INT
    ,@Nombre VARCHAR(100)
    ,@Accion CHAR(1)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION
        IF (@Nombre IS NULL OR LTRIM(RTRIM(@Nombre)) = '')
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        IF (@Accion NOT IN ('C', 'D'))
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        IF EXISTS
        (
            SELECT 1
            FROM TipoDeMovimiento
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
            FROM TipoDeMovimiento
            WHERE Nombre = @Nombre
        )
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        INSERT INTO TipoDeMovimiento
        (
            Id,
            Nombre,
            Acción
        )
        VALUES
        (
            @Id,
            @Nombre,
            @Accion
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


