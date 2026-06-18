USE [tareaProgramada3]
GO

/****** Object:  StoredProcedure [dbo].[EliminarEmpleado]    Script Date: 18/06/2026 12:44:24 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[EliminarEmpleado]
    @ValorDocumentoIdentidad INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @IdEmpleado INT;

        BEGIN TRANSACTION;

        SELECT @IdEmpleado = Id
        FROM dbo.Empleado
        WHERE ValorDocumentoIdentidad = @ValorDocumentoIdentidad;

        IF @IdEmpleado IS NULL
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Empleado
            WHERE Id = @IdEmpleado
              AND EsActivo = 1
        )
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END;

        UPDATE dbo.Empleado
        SET EsActivo = 0
        WHERE Id = @IdEmpleado;

        UPDATE dbo.EmpleadoDeduccion
        SET Activa = 0,
            FechaFin = GETDATE()
        WHERE idEmpleado = @IdEmpleado
          AND Activa = 1;

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


