USE [tareaProgramada3]
GO

/****** Object:  StoredProcedure [dbo].[InsertarTipoDeduccion]    Script Date: 15/06/2026 11:00:25 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertarTipoDeduccion]
    @Id INT,
    @Nombre VARCHAR(100),
    @Obligatorio BIT,
    @Porcentual BIT,
    @Valor REAL,
    @NombreTipoMovimiento VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        BEGIN TRANSACTION

        DECLARE @IdTipoMovimiento INT

        IF (@Nombre IS NULL OR @Nombre = '')
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        IF EXISTS
        (
            SELECT 1
            FROM TipoDeDeduccion
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
            FROM TipoDeDeduccion
            WHERE Nombre = @Nombre
        )
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        -- Buscar TipoMovimiento
        SELECT @IdTipoMovimiento = Id
        FROM TipoDeMovimiento
        WHERE Nombre = @NombreTipoMovimiento

        IF (@IdTipoMovimiento IS NULL)
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        INSERT INTO TipoDeDeduccion
        (
            Id,
            Obligatorio,
            Porcentual,
            Valor,
            IdTipoMov,
            Nombre
        )
        VALUES
        (
            @Id,
            @Obligatorio,
            @Porcentual,
            @Valor,
            @IdTipoMovimiento,
            @Nombre
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


