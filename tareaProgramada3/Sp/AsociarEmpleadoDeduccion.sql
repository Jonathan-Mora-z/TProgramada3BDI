USE [tareaProgramada3]
GO

/****** Object:  StoredProcedure [dbo].[AsociarEmpleadoDeduccion]    Script Date: 18/06/2026 12:41:30 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[AsociarEmpleadoDeduccion]
    @ValorDocumentoIdentidad INT,
    @TipoDeduccion VARCHAR(64),
    @MontoFijo DECIMAL(18,2),
    @FechaInicio DATE = NULL
AS
BEGIN

    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @IdEmpleado INT;
        DECLARE @IdTipoDeduccion INT;
        DECLARE @IdEmpleadoDeduccion INT;
        DECLARE @Obligatorio BIT;
        DECLARE @FechaInicioFinal DATE;

        SET @FechaInicioFinal = ISNULL(@FechaInicio, CONVERT(DATE, GETDATE()));

        BEGIN TRANSACTION;

        SELECT @IdEmpleado = Id
        FROM dbo.Empleado
        WHERE ValorDocumentoIdentidad = @ValorDocumentoIdentidad
          AND EsActivo = 1;

        IF @IdEmpleado IS NULL
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        SELECT
            @IdTipoDeduccion = Id,
            @Obligatorio = Obligatorio
        FROM dbo.TipoDeDeduccion
        WHERE Nombre = @TipoDeduccion;

        IF @IdTipoDeduccion IS NULL
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        IF @Obligatorio = 1
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        IF EXISTS
        (
            SELECT 1
            FROM dbo.EmpleadoDeduccion
            WHERE idEmpleado = @IdEmpleado
              AND idTipoDeduccion = @IdTipoDeduccion
              AND Activa = 1
        )
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        SELECT @IdEmpleadoDeduccion = ISNULL(MAX(Id), 0) + 1
        FROM dbo.EmpleadoDeduccion;

        INSERT INTO dbo.EmpleadoDeduccion
        (
            id,
            idEmpleado,
            idTipoDeduccion,
            FechaInicio,
            FechaFin,
            Activa,
            Monto
        )
        VALUES
        (
            @IdEmpleadoDeduccion,
            @IdEmpleado,
            @IdTipoDeduccion,
            @FechaInicioFinal,
            NULL,
            1,
            @MontoFijo
        );

        COMMIT;

        SELECT 0 AS Resultado;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK;

        INSERT INTO dbo.DBError
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


