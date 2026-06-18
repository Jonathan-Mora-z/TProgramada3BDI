USE [tareaProgramada3]
GO

/****** Object:  StoredProcedure [dbo].[AsociarEmpleadoDeduccion]    Script Date: 17/06/2026 10:46:08 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AsociarEmpleadoDeduccion]
    @ValorDocumentoIdentidad INT,
    @TipoDeduccion VARCHAR(64),
    @MontoFijo DECIMAL(18,2)
AS
BEGIN

    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @IdEmpleado INT;
        DECLARE @IdTipoDeduccion INT;
        DECLARE @IdEmpleadoDeduccion INT;

        BEGIN TRANSACTION;

        SELECT @IdEmpleado = Id
        FROM Empleado
        WHERE ValorDocumentoIdentidad = @ValorDocumentoIdentidad;

        IF @IdEmpleado IS NULL
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        SELECT @IdTipoDeduccion = Id
        FROM TipoDeDeduccion
        WHERE Nombre = @TipoDeduccion;

        IF @IdTipoDeduccion IS NULL
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        IF EXISTS
        (
            SELECT 1
            FROM EmpleadoDeduccion
            WHERE idEmpleado = @IdEmpleado
              AND idTipoDeduccion = @IdTipoDeduccion
              AND Activa = 1
        )
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        SELECT @IdEmpleadoDeduccion =
            ISNULL(MAX(Id),0) + 1
        FROM EmpleadoDeduccion;

        INSERT INTO EmpleadoDeduccion
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
            GETDATE(),
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


