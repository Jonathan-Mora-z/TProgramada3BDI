USE [tareaProgramada3]
GO

/****** Object:  StoredProcedure [dbo].[CerrarSemanaPlanilla]    Script Date: 18/06/2026 12:42:07 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE [dbo].[CerrarSemanaPlanilla]
    @FechaInicioSemana DATE
AS
BEGIN

    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @IdSemanaPlanilla INT;
        DECLARE @IdMesPlanilla INT;
        DECLARE @FechaFinSemana DATE;

        DECLARE @FechaInicioMes DATE;
        DECLARE @FechaFinMes DATE;
        DECLARE @CantidadSemanasMes INT;

        DECLARE @IdPlanillaMensualBase INT;
        DECLARE @IdMovimientoPlanillaBase INT;
        DECLARE @IdMovimientoXDeduccionBase INT;
        DECLARE @IdMesPlanillaXDeduccionBase INT;

        BEGIN TRANSACTION;

        SELECT
            @IdSemanaPlanilla = sp.Id,
            @IdMesPlanilla = sp.IdMesPlanilla,
            @FechaFinSemana = sp.FechaFin
        FROM dbo.SemanaPlanilla AS sp
        WHERE sp.FechaInicio = @FechaInicioSemana;

        IF @IdSemanaPlanilla IS NULL
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        IF EXISTS
        (
            SELECT 1
            FROM dbo.MovimientoPlanilla AS mp
            INNER JOIN dbo.MovimientoXDeduccion AS mxd
                ON mxd.idMovimientoPlanilla = mp.Id
            WHERE mp.idSemanalPlanilla = @IdSemanaPlanilla
        )
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        SELECT
            @FechaInicioMes = mp.FechaInicio,
            @FechaFinMes = mp.FechaFin
        FROM dbo.MesPlanilla AS mp
        WHERE mp.Id = @IdMesPlanilla;

        IF @FechaInicioMes IS NULL
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        SET @CantidadSemanasMes =
            (DATEDIFF(DAY, @FechaInicioMes, @FechaFinMes) + 1) / 7;

        IF @CantidadSemanasMes NOT IN (4, 5)
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        SELECT @IdPlanillaMensualBase = ISNULL(MAX(Id), 0)
        FROM dbo.PlanillaMensualEmpleado;

        INSERT INTO dbo.PlanillaMensualEmpleado
        (
            Id,
            IdMesPlanilla,
            IdEmpleado,
            SalarioBruto,
            TotalDeducciones,
            SalarioNeto
        )
        SELECT
            @IdPlanillaMensualBase
                + ROW_NUMBER() OVER (ORDER BY pse.IdEmpleado),
            @IdMesPlanilla,
            pse.IdEmpleado,
            0,
            0,
            0
        FROM dbo.PlanillaSemanalEmpleado AS pse
        WHERE pse.idSemanaPlanilla = @IdSemanaPlanilla
          AND NOT EXISTS
          (
              SELECT 1
              FROM dbo.PlanillaMensualEmpleado AS pme
              WHERE pme.IdMesPlanilla = @IdMesPlanilla
                AND pme.IdEmpleado = pse.IdEmpleado
          );

        CREATE TABLE #DeduccionesSemana
        (
            Id INT IDENTITY(1,1),
            IdPlanillaSemanalEmpleado INT,
            IdPlanillaMensualEmpleado INT,
            IdEmpleado INT,
            IdTipoDeduccion INT,
            IdTipoMovimiento INT,
            Monto DECIMAL(18,0),
            IdMovimientoPlanilla INT NULL
        );

        INSERT INTO #DeduccionesSemana
        (
            IdPlanillaSemanalEmpleado,
            IdPlanillaMensualEmpleado,
            IdEmpleado,
            IdTipoDeduccion,
            IdTipoMovimiento,
            Monto
        )
        SELECT
            pse.Id,
            pme.Id,
            pse.IdEmpleado,
            td.Id,
            td.IdTipoMov,
            CASE
                WHEN td.Porcentual = 1
                    THEN ROUND
                    (
                        pse.SalarioBruto * CAST(td.Valor AS DECIMAL(18,6)),
                        0
                    )
                ELSE ROUND
                    (
                        CAST(ISNULL(ed.Monto, 0) AS DECIMAL(18,2))
                        / @CantidadSemanasMes,
                        0
                    )
            END AS Monto
        FROM dbo.PlanillaSemanalEmpleado AS pse
        INNER JOIN dbo.PlanillaMensualEmpleado AS pme
            ON pme.IdEmpleado = pse.IdEmpleado
           AND pme.IdMesPlanilla = @IdMesPlanilla
        INNER JOIN dbo.EmpleadoDeduccion AS ed
            ON ed.idEmpleado = pse.IdEmpleado
        INNER JOIN dbo.TipoDeDeduccion AS td
            ON td.Id = ed.idTipoDeduccion
        WHERE pse.idSemanaPlanilla = @IdSemanaPlanilla
          AND ed.FechaInicio <= @FechaFinSemana
          AND
          (
              ed.FechaFin IS NULL
              OR ed.FechaFin >= @FechaInicioSemana
          );

        IF EXISTS
        (
            SELECT 1
            FROM #DeduccionesSemana
            WHERE IdTipoMovimiento IS NULL
        )
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        SELECT @IdMovimientoPlanillaBase = ISNULL(MAX(Id), 0)
        FROM dbo.MovimientoPlanilla;

        UPDATE #DeduccionesSemana
        SET IdMovimientoPlanilla = @IdMovimientoPlanillaBase + Id;

        INSERT INTO dbo.MovimientoPlanilla
        (
            Id,
            idSemanalPlanilla,
            idTipoMovimiento,
            idMovimientoHoras,
            Fecha,
            Monto
        )
        SELECT
            IdMovimientoPlanilla,
            @IdSemanaPlanilla,
            IdTipoMovimiento,
            NULL,
            GETDATE(),
            Monto
        FROM #DeduccionesSemana;

        SELECT @IdMovimientoXDeduccionBase = ISNULL(MAX(Id), 0)
        FROM dbo.MovimientoXDeduccion;

        INSERT INTO dbo.MovimientoXDeduccion
        (
            Id,
            idMovimientoPlanilla,
            idTipoDeduccion
        )
        SELECT
            @IdMovimientoXDeduccionBase
                + ROW_NUMBER() OVER (ORDER BY Id),
            IdMovimientoPlanilla,
            IdTipoDeduccion
        FROM #DeduccionesSemana;

        ;WITH DeduccionesPorEmpleado AS
        (
            SELECT
                IdPlanillaSemanalEmpleado,
                SUM(Monto) AS TotalDeducciones
            FROM #DeduccionesSemana
            GROUP BY IdPlanillaSemanalEmpleado
        )
        UPDATE pse
        SET
            pse.TotalDeducciones =
                pse.TotalDeducciones + ISNULL(d.TotalDeducciones, 0),
            pse.SalarioNeto =
                pse.SalarioBruto
                - (pse.TotalDeducciones + ISNULL(d.TotalDeducciones, 0))
        FROM dbo.PlanillaSemanalEmpleado AS pse
        LEFT JOIN DeduccionesPorEmpleado AS d
            ON d.IdPlanillaSemanalEmpleado = pse.Id
        WHERE pse.idSemanaPlanilla = @IdSemanaPlanilla;

        UPDATE pme
        SET
            pme.SalarioBruto =
                pme.SalarioBruto + pse.SalarioBruto,
            pme.TotalDeducciones =
                pme.TotalDeducciones + pse.TotalDeducciones,
            pme.SalarioNeto =
                pme.SalarioNeto + pse.SalarioNeto
        FROM dbo.PlanillaMensualEmpleado AS pme
        INNER JOIN dbo.PlanillaSemanalEmpleado AS pse
            ON pse.IdEmpleado = pme.IdEmpleado
        WHERE pse.idSemanaPlanilla = @IdSemanaPlanilla
          AND pme.IdMesPlanilla = @IdMesPlanilla;

        ;WITH DeduccionesMes AS
        (
            SELECT
                @IdMesPlanilla AS IdMesPlanilla,
                IdTipoDeduccion,
                SUM(Monto) AS Monto
            FROM #DeduccionesSemana
            GROUP BY IdTipoDeduccion
        )
        UPDATE mpd
        SET mpd.Monto = mpd.Monto + dm.Monto
        FROM dbo.MesPlanillaXDeduccion AS mpd
        INNER JOIN DeduccionesMes AS dm
            ON dm.IdMesPlanilla = mpd.idPlanillaMensual
           AND dm.IdTipoDeduccion = mpd.idTipoDeduccion;

        SELECT @IdMesPlanillaXDeduccionBase = ISNULL(MAX(Id), 0)
        FROM dbo.MesPlanillaXDeduccion;

        ;WITH DeduccionesMes AS
        (
            SELECT
                @IdMesPlanilla AS IdMesPlanilla,
                IdTipoDeduccion,
                SUM(Monto) AS Monto
            FROM #DeduccionesSemana
            GROUP BY IdTipoDeduccion
        )
        INSERT INTO dbo.MesPlanillaXDeduccion
        (
            Id,
            idPlanillaMensual,
            idTipoDeduccion,
            Monto
        )
        SELECT
            @IdMesPlanillaXDeduccionBase
                + ROW_NUMBER() OVER
                (
                    ORDER BY
                        dm.IdMesPlanilla,
                        dm.IdTipoDeduccion
                ),
            dm.IdMesPlanilla,
            dm.IdTipoDeduccion,
            dm.Monto
        FROM DeduccionesMes AS dm
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.MesPlanillaXDeduccion AS mpd
            WHERE mpd.idPlanillaMensual = dm.IdMesPlanilla
              AND mpd.idTipoDeduccion = dm.IdTipoDeduccion
        );

        DROP TABLE #DeduccionesSemana;

        COMMIT;

        SELECT
            0 AS Resultado,
            @IdSemanaPlanilla AS IdSemanaPlanilla,
            @IdMesPlanilla AS IdMesPlanilla;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK;

        IF OBJECT_ID('tempdb..#DeduccionesSemana') IS NOT NULL
            DROP TABLE #DeduccionesSemana;

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


