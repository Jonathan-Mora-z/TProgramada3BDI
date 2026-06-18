USE [tareaProgramada3]
GO

/****** Object:  StoredProcedure [dbo].[MarcarAsistencia]    Script Date: 18/06/2026 12:46:05 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[MarcarAsistencia]
    @ValorDocumentoIdentidad INT,
    @HoraEntrada DATETIME,
    @HoraSalida DATETIME
AS
BEGIN

    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @IdEmpleado INT;
        DECLARE @IdAsistencia INT;
        DECLARE @IdSemanaPlanilla INT;
        DECLARE @IdPlanillaSemanalEmpleado INT;
        DECLARE @IdTipoJornada INT;

        DECLARE @HoraInicioJornada TIME(0);
        DECLARE @HoraFinJornada TIME(0);

        DECLARE @FechaPlanilla DATE;
        DECLARE @FechaEntrada DATE;

        DECLARE @InicioJornada DATETIME;
        DECLARE @FinJornada DATETIME;

        DECLARE @HorasJornada INT;
        DECLARE @HorasTotales INT;
        DECLARE @HorasExtraTotal INT;
        DECLARE @HorasOrdinarias INT;
        DECLARE @HorasExtraNormales INT;
        DECLARE @HorasExtraDobles INT;

        DECLARE @Contador INT;
        DECLARE @FechaHoraExtra DATE;
        DECLARE @InicioHoraExtra DATETIME;

        DECLARE @SalarioXHora DECIMAL(18,2);

        DECLARE @IdTipoMovOrdinario INT;
        DECLARE @IdTipoMovExtraNormal INT;
        DECLARE @IdTipoMovExtraDoble INT;

        DECLARE @IdMovimientoHoras INT;
        DECLARE @IdMovimientoPlanilla INT;

        DECLARE @MontoOrdinario DECIMAL(18,0);
        DECLARE @MontoExtraNormal DECIMAL(18,0);
        DECLARE @MontoExtraDoble DECIMAL(18,0);
        DECLARE @MontoTotal DECIMAL(18,0);

        IF @HoraSalida <= @HoraEntrada
        BEGIN
            SELECT 50008 AS Resultado;
            RETURN;
        END

        BEGIN TRANSACTION;

        SELECT
            @IdEmpleado = e.Id,
            @SalarioXHora = CAST(p.SalarioXHora AS DECIMAL(18,2))
        FROM dbo.Empleado AS e
        INNER JOIN dbo.Puesto AS p
            ON p.Id = e.IdPuesto
        WHERE e.ValorDocumentoIdentidad = @ValorDocumentoIdentidad
          AND e.EsActivo = 1;

        IF @IdEmpleado IS NULL
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        SET @FechaPlanilla = CONVERT(DATE, @HoraSalida);
        SET @FechaEntrada = CONVERT(DATE, @HoraEntrada);

        SELECT @IdSemanaPlanilla = sp.Id
        FROM dbo.SemanaPlanilla AS sp
        WHERE @FechaPlanilla BETWEEN sp.FechaInicio AND sp.FechaFin;

        IF @IdSemanaPlanilla IS NULL
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        SELECT @IdPlanillaSemanalEmpleado = pse.Id
        FROM dbo.PlanillaSemanalEmpleado AS pse
        WHERE pse.idSemanaPlanilla = @IdSemanaPlanilla
          AND pse.IdEmpleado = @IdEmpleado;

        IF @IdPlanillaSemanalEmpleado IS NULL
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        SELECT TOP 1
            @IdTipoJornada = je.IdTipoJornada,
            @HoraInicioJornada = tj.HoraInicio,
            @HoraFinJornada = tj.HoraFin
        FROM dbo.JornadaEmpleado AS je
        INNER JOIN dbo.TipoDeJornada AS tj
            ON tj.Id = je.IdTipoJornada
        WHERE je.IdEmpleado = @IdEmpleado
          AND @FechaPlanilla BETWEEN je.FechaInicioSemana AND je.FechaSinSemana
        ORDER BY je.FechaInicioSemana DESC;

        IF @IdTipoJornada IS NULL
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        SELECT @IdTipoMovOrdinario = Id
        FROM dbo.TipoDeMovimiento
        WHERE Nombre = 'Credito Horas ordinarias';

        SELECT @IdTipoMovExtraNormal = Id
        FROM dbo.TipoDeMovimiento
        WHERE Nombre = 'Credito Horas Extra Normales';

        SELECT @IdTipoMovExtraDoble = Id
        FROM dbo.TipoDeMovimiento
        WHERE Nombre = 'Credito Horas Extra Dobles';

        IF @IdTipoMovOrdinario IS NULL
           OR @IdTipoMovExtraNormal IS NULL
           OR @IdTipoMovExtraDoble IS NULL
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END


        SET @InicioJornada = DATEADD
        (
            SECOND,
            DATEDIFF(SECOND, CAST('00:00:00' AS TIME), @HoraInicioJornada),
            CAST(@FechaEntrada AS DATETIME)
        );

        SET @FinJornada = DATEADD
        (
            SECOND,
            DATEDIFF(SECOND, CAST('00:00:00' AS TIME), @HoraFinJornada),
            CAST(@FechaEntrada AS DATETIME)
        );

        -- Si la jornada termina al día siguiente, por ejemplo nocturna
        IF @HoraFinJornada <= @HoraInicioJornada
        BEGIN
            SET @FinJornada = DATEADD(DAY, 1, @FinJornada);
        END

        SET @HorasJornada = DATEDIFF(MINUTE, @InicioJornada, @FinJornada) / 60;

        IF @HorasJornada <= 0
        BEGIN
            SET @HorasJornada = 8;
        END


        SET @HorasTotales = DATEDIFF(MINUTE, @HoraEntrada, @HoraSalida) / 60;

        IF @HorasTotales <= 0
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        SET @HorasExtraTotal = 0;

        IF @HoraSalida > @FinJornada
        BEGIN
            SET @HorasExtraTotal = DATEDIFF(MINUTE, @FinJornada, @HoraSalida) / 60;
        END

        IF @HorasExtraTotal < 0
        BEGIN
            SET @HorasExtraTotal = 0;
        END

        SET @HorasOrdinarias = @HorasTotales - @HorasExtraTotal;

        IF @HorasOrdinarias > @HorasJornada
        BEGIN
            SET @HorasOrdinarias = @HorasJornada;
        END

        IF @HorasOrdinarias < 0
        BEGIN
            SET @HorasOrdinarias = 0;
        END


        SET @HorasExtraNormales = 0;
        SET @HorasExtraDobles = 0;
        SET @Contador = 0;

        WHILE @Contador < @HorasExtraTotal
        BEGIN

            SET @InicioHoraExtra = DATEADD(HOUR, @Contador, @FinJornada);
            SET @FechaHoraExtra = CONVERT(DATE, @InicioHoraExtra);

            -- Domingo o feriado = hora extra doble
            IF (DATEDIFF(DAY, '19000107', @FechaHoraExtra) % 7 = 0)
               OR EXISTS
               (
                   SELECT 1
                   FROM dbo.Feriado AS f
                   WHERE f.Fecha = @FechaHoraExtra
               )
            BEGIN
                SET @HorasExtraDobles = @HorasExtraDobles + 1;
            END
            ELSE
            BEGIN
                SET @HorasExtraNormales = @HorasExtraNormales + 1;
            END

            SET @Contador = @Contador + 1;

        END


        SELECT @IdAsistencia = ISNULL(MAX(id), 0) + 1
        FROM dbo.Asistencia;

        INSERT INTO dbo.Asistencia
        (
            id,
            idEmpleado,
            FechaEntrada,
            FechaSalida
        )
        VALUES
        (
            @IdAsistencia,
            @IdEmpleado,
            @HoraEntrada,
            @HoraSalida
        );


        SET @MontoOrdinario = 0;
        SET @MontoExtraNormal = 0;
        SET @MontoExtraDoble = 0;
        SET @MontoTotal = 0;


        IF @HorasOrdinarias > 0
        BEGIN

            SELECT @IdMovimientoHoras = ISNULL(MAX(id), 0) + 1
            FROM dbo.MovimientoHoras;

            INSERT INTO dbo.MovimientoHoras
            (
                id,
                idAsistencia,
                CantidadHoras,
                TipoHora
            )
            VALUES
            (
                @IdMovimientoHoras,
                @IdAsistencia,
                @HorasOrdinarias,
                'Ordinario'
            );

            SET @MontoOrdinario = ROUND(@HorasOrdinarias * @SalarioXHora, 0);

            SELECT @IdMovimientoPlanilla = ISNULL(MAX(id), 0) + 1
            FROM dbo.MovimientoPlanilla;

            INSERT INTO dbo.MovimientoPlanilla
            (
                id,
                idSemanalPlanilla,
                idTipoMovimiento,
                idMovimientoHoras,
                Fecha,
                Monto
            )
            VALUES
            (
                @IdMovimientoPlanilla,
                @IdSemanaPlanilla,
                @IdTipoMovOrdinario,
                @IdMovimientoHoras,
                GETDATE(),
                @MontoOrdinario
            );

            SET @MontoTotal = @MontoTotal + @MontoOrdinario;

        END


        IF @HorasExtraNormales > 0
        BEGIN

            SELECT @IdMovimientoHoras = ISNULL(MAX(id), 0) + 1
            FROM dbo.MovimientoHoras;

            INSERT INTO dbo.MovimientoHoras
            (
                id,
                idAsistencia,
                CantidadHoras,
                TipoHora
            )
            VALUES
            (
                @IdMovimientoHoras,
                @IdAsistencia,
                @HorasExtraNormales,
                'Extra'
            );

            SET @MontoExtraNormal = ROUND(@HorasExtraNormales * @SalarioXHora * 1.5, 0);

            SELECT @IdMovimientoPlanilla = ISNULL(MAX(id), 0) + 1
            FROM dbo.MovimientoPlanilla;

            INSERT INTO dbo.MovimientoPlanilla
            (
                id,
                idSemanalPlanilla,
                idTipoMovimiento,
                idMovimientoHoras,
                Fecha,
                Monto
            )
            VALUES
            (
                @IdMovimientoPlanilla,
                @IdSemanaPlanilla,
                @IdTipoMovExtraNormal,
                @IdMovimientoHoras,
                GETDATE(),
                @MontoExtraNormal
            );

            SET @MontoTotal = @MontoTotal + @MontoExtraNormal;

        END


        IF @HorasExtraDobles > 0
        BEGIN

            SELECT @IdMovimientoHoras = ISNULL(MAX(id), 0) + 1
            FROM dbo.MovimientoHoras;

            INSERT INTO dbo.MovimientoHoras
            (
                id,
                idAsistencia,
                CantidadHoras,
                TipoHora
            )
            VALUES
            (
                @IdMovimientoHoras,
                @IdAsistencia,
                @HorasExtraDobles,
                'Doble'
            );

            SET @MontoExtraDoble = ROUND(@HorasExtraDobles * @SalarioXHora * 2, 0);

            SELECT @IdMovimientoPlanilla = ISNULL(MAX(id), 0) + 1
            FROM dbo.MovimientoPlanilla;

            INSERT INTO dbo.MovimientoPlanilla
            (
                id,
                idSemanalPlanilla,
                idTipoMovimiento,
                idMovimientoHoras,
                Fecha,
                Monto
            )
            VALUES
            (
                @IdMovimientoPlanilla,
                @IdSemanaPlanilla,
                @IdTipoMovExtraDoble,
                @IdMovimientoHoras,
                GETDATE(),
                @MontoExtraDoble
            );

            SET @MontoTotal = @MontoTotal + @MontoExtraDoble;

        END


        UPDATE dbo.PlanillaSemanalEmpleado
        SET
            SalarioBruto = SalarioBruto + @MontoTotal,
            SalarioNeto = (SalarioBruto + @MontoTotal) - TotalDeducciones,
            HorasOrdinarias = HorasOrdinarias + @HorasOrdinarias,
            HorasExtra = HorasExtra + @HorasExtraNormales,
            HorasExtraDobles = HorasExtraDobles + @HorasExtraDobles
        WHERE id = @IdPlanillaSemanalEmpleado;

        COMMIT;

        SELECT
            0 AS Resultado,
            @IdAsistencia AS IdAsistencia,
            @HorasOrdinarias AS HorasOrdinarias,
            @HorasExtraNormales AS HorasExtraNormales,
            @HorasExtraDobles AS HorasExtraDobles,
            @MontoTotal AS MontoGenerado;

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


