USE [tareaProgramada3]
GO

/****** Object:  StoredProcedure [dbo].[AbrirSemanaPlanilla]    Script Date: 18/06/2026 12:41:01 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE [dbo].[AbrirSemanaPlanilla]
    @FechaInicio DATE
AS
BEGIN

    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @IdSemanaPlanilla INT;
        DECLARE @IdMesPlanilla INT;
        DECLARE @FechaFin DATE;
        DECLARE @IdPlanillaSemanalEmpleadoBase INT;

        BEGIN TRANSACTION;


        IF (DATEDIFF(DAY, '19000105', @FechaInicio) % 7) <> 0
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END


        SET @FechaFin = DATEADD(DAY, 6, @FechaInicio);


        SELECT @IdMesPlanilla = id
        FROM dbo.MesPlanilla
        WHERE @FechaInicio BETWEEN FechaInicio AND FechaFin;

        IF @IdMesPlanilla IS NULL
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        IF EXISTS
        (
            SELECT 1
            FROM dbo.SemanaPlanilla
            WHERE FechaInicio = @FechaInicio
        )
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        SELECT @IdSemanaPlanilla = ISNULL(MAX(id), 0) + 1
        FROM dbo.SemanaPlanilla;

        INSERT INTO dbo.SemanaPlanilla
        (
            id,
            FechaInicio,
            FechaFin,
            IdMesPlanilla
        )
        VALUES
        (
            @IdSemanaPlanilla,
            @FechaInicio,
            @FechaFin,
            @IdMesPlanilla
        );

        SELECT @IdPlanillaSemanalEmpleadoBase = ISNULL(MAX(id), 0)
        FROM dbo.PlanillaSemanalEmpleado;

        INSERT INTO dbo.PlanillaSemanalEmpleado
        (
            id,
            idSemanaPlanilla,
            IdEmpleado,
            SalarioBruto,
            TotalDeducciones,
            SalarioNeto,
            HorasOrdinarias,
            HorasExtra,
            HorasExtraDobles
        )
        SELECT
            @IdPlanillaSemanalEmpleadoBase
                + ROW_NUMBER() OVER (ORDER BY e.Id) AS id,
            @IdSemanaPlanilla AS idSemanaPlanilla,
            e.Id AS IdEmpleado,
            0 AS SalarioBruto,
            0 AS TotalDeducciones,
            0 AS SalarioNeto,
            0 AS HorasOrdinarias,
            0 AS HorasExtra,
            0 AS HorasExtraDobles
        FROM dbo.Empleado AS e
        WHERE e.EsActivo = 1;

        COMMIT;

        SELECT
            0 AS Resultado,
            @IdSemanaPlanilla AS IdSemanaPlanilla,
            @IdMesPlanilla AS IdMesPlanilla,
            @FechaInicio AS FechaInicio,
            @FechaFin AS FechaFin;

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


