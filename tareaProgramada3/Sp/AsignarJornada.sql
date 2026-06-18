USE [tareaProgramada3]
GO

/****** Object:  StoredProcedure [dbo].[AsignarJornada]    Script Date: 18/06/2026 12:41:17 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AsignarJornada]
    @ValorDocumentoIdentidad INT,
    @Jornada VARCHAR(100),
    @InicioSemana DATE
AS
BEGIN

    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @IdEmpleado INT;
        DECLARE @IdTipoJornada INT;
        DECLARE @IdJornadaEmpleado INT;

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

        SELECT @IdTipoJornada = Id
        FROM TipoDeJornada
        WHERE Nombre = @Jornada;

        IF @IdTipoJornada IS NULL
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        IF EXISTS
        (
            SELECT 1
            FROM JornadaEmpleado
            WHERE IdEmpleado = @IdEmpleado
              AND FechaInicioSemana = @InicioSemana
        )
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        SELECT @IdJornadaEmpleado =
            ISNULL(MAX(Id),0) + 1
        FROM JornadaEmpleado;

        INSERT INTO JornadaEmpleado
        (
            Id,
            IdEmpleado,
            IdTipoJornada,
            FechaInicioSemana,
            FechaSinSemana
        )
        VALUES
        (
            @IdJornadaEmpleado,
            @IdEmpleado,
            @IdTipoJornada,
            @InicioSemana,
            DATEADD(DAY, 6, @InicioSemana)
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


