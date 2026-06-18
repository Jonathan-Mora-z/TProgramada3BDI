USE [tareaProgramada3]
GO

/****** Object:  StoredProcedure [dbo].[AbrirMesPlanilla]    Script Date: 18/06/2026 12:40:33 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE [dbo].[AbrirMesPlanilla]
    @FechaInicio DATE
AS
BEGIN

    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @IdMesPlanilla INT;
        DECLARE @IdPlanillaMensualEmpleadoBase INT;
        DECLARE @PrimerDiaMes DATE;
        DECLARE @PrimerViernesMes DATE;
        DECLARE @PrimerDiaMesSiguiente DATE;
        DECLARE @PrimerViernesMesSiguiente DATE;
        DECLARE @FechaFin DATE;

        BEGIN TRANSACTION;


        SET @PrimerDiaMes = DATEFROMPARTS
        (
            YEAR(@FechaInicio),
            MONTH(@FechaInicio),
            1
        );

        SET @PrimerViernesMes = DATEADD
        (
            DAY,
            (7 - (DATEDIFF(DAY, '19000105', @PrimerDiaMes) % 7)) % 7,
            @PrimerDiaMes
        );

        IF @FechaInicio <> @PrimerViernesMes
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END


        SET @PrimerDiaMesSiguiente = DATEADD(MONTH, 1, @PrimerDiaMes);

        SET @PrimerViernesMesSiguiente = DATEADD
        (
            DAY,
            (7 - (DATEDIFF(DAY, '19000105', @PrimerDiaMesSiguiente) % 7)) % 7,
            @PrimerDiaMesSiguiente
        );

        SET @FechaFin = DATEADD(DAY, -1, @PrimerViernesMesSiguiente);


        IF EXISTS
        (
            SELECT 1
            FROM dbo.MesPlanilla
            WHERE FechaInicio = @FechaInicio
        )
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END


        SELECT @IdMesPlanilla = ISNULL(MAX(id), 0) + 1
        FROM dbo.MesPlanilla;

        INSERT INTO dbo.MesPlanilla
        (
            id,
            FechaInicio,
            FechaFin
        )
        VALUES
        (
            @IdMesPlanilla,
            @FechaInicio,
            @FechaFin
        );


        SELECT @IdPlanillaMensualEmpleadoBase = ISNULL(MAX(id), 0)
        FROM dbo.PlanillaMensualEmpleado;


        INSERT INTO dbo.PlanillaMensualEmpleado
        (
            id,
            IdMesPlanilla,
            IdEmpleado,
            SalarioBruto,
            TotalDeducciones,
            SalarioNeto
        )
        SELECT
            @IdPlanillaMensualEmpleadoBase
                + ROW_NUMBER() OVER (ORDER BY e.Id) AS id,
            @IdMesPlanilla AS IdMesPlanilla,
            e.Id AS IdEmpleado,
            0 AS SalarioBruto,
            0 AS TotalDeducciones,
            0 AS SalarioNeto
        FROM dbo.Empleado AS e
        WHERE e.EsActivo = 1;

        COMMIT;

        SELECT
            0 AS Resultado,
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


