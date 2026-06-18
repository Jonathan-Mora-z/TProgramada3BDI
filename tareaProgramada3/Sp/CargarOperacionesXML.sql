USE [tareaProgramada3]
GO

/****** Object:  StoredProcedure [dbo].[CargarOperacionesXML]    Script Date: 18/06/2026 12:41:56 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[CargarOperacionesXML]
    @xml XML
AS
BEGIN

    SET NOCOUNT ON;

    BEGIN TRY

        CREATE TABLE #Operaciones
        (
            Id INT IDENTITY(1,1),
            FechaOperacion DATE,
            TipoOperacion VARCHAR(100),
            Nodo XML
        );

        CREATE TABLE #Fechas
        (
            Id INT IDENTITY(1,1),
            FechaOperacion DATE
        );

        INSERT INTO #Operaciones
        (
            FechaOperacion,
            TipoOperacion,
            Nodo
        )
        SELECT
            F.O.value('@Fecha', 'DATE') AS FechaOperacion,
            T.N.value('local-name(.)', 'VARCHAR(100)') AS TipoOperacion,
            T.N.query('.') AS Nodo
        FROM @xml.nodes('/Operaciones/FechaOperacion') AS F(O)
        CROSS APPLY F.O.nodes('*') AS T(N);

        INSERT INTO #Fechas
        (
            FechaOperacion
        )
        SELECT DISTINCT FechaOperacion
        FROM #Operaciones
        ORDER BY FechaOperacion;

        ---------------------------------------------------
        -- VARIABLES GENERALES
        ---------------------------------------------------

        DECLARE @IdFechaActual INT = 1;
        DECLARE @MaxIdFecha INT;
        DECLARE @FechaOperacion DATE;

        DECLARE @IdOperacionActual INT;
        DECLARE @TipoOperacion VARCHAR(100);
        DECLARE @Nodo XML;

        DECLARE @CantidadAsistenciasFecha INT;

        DECLARE @FechaInicioSemana DATE;
        DECLARE @FechaSiguiente DATE;
        DECLARE @FechaInicioAplicacion DATE;
        DECLARE @FechaFinAplicacion DATE;

        DECLARE @FechaPlanillaMarca DATE;
        DECLARE @FechaInicioSemanaMarca DATE;

        DECLARE @PrimerDiaMes DATE;
        DECLARE @PrimerViernesMes DATE;
        DECLARE @PrimerDiaMesAnterior DATE;
        DECLARE @PrimerViernesMesAnterior DATE;
        DECLARE @FechaInicioMes DATE;

        DECLARE @IdSemanaActual INT;
        DECLARE @IdMesActual INT;

        DECLARE @ValorDocumentoIdentidad INT;
        DECLARE @Nombre VARCHAR(128);
        DECLARE @NombrePuesto VARCHAR(64);
        DECLARE @CuentaBancaria VARCHAR(128);
        DECLARE @Username VARCHAR(100);
        DECLARE @Pwd VARCHAR(100);
        DECLARE @TipoUsuario INT;
        DECLARE @FechaContratacion DATE;

        DECLARE @TipoDeduccion VARCHAR(128);
        DECLARE @MontoFijo DECIMAL(18,2);

        DECLARE @Jornada VARCHAR(100);
        DECLARE @InicioSemana DATE;

        DECLARE @HoraEntrada DATETIME;
        DECLARE @HoraSalida DATETIME;

        DECLARE @IdEmpleadoOperacion INT;

        SELECT @MaxIdFecha = ISNULL(MAX(Id), 0)
        FROM #Fechas;

        ---------------------------------------------------
        -- RECORRER FECHAS
        ---------------------------------------------------

        WHILE @IdFechaActual <= @MaxIdFecha
        BEGIN

            SELECT @FechaOperacion = FechaOperacion
            FROM #Fechas
            WHERE Id = @IdFechaActual;

            SELECT @CantidadAsistenciasFecha = COUNT(*)
            FROM #Operaciones
            WHERE FechaOperacion = @FechaOperacion
              AND TipoOperacion = 'MarcaAsistencia';

            ---------------------------------------------------
            -- Semana actual de la fecha de operación
            -- Semana inicia viernes
            ---------------------------------------------------

            SET @FechaInicioSemana = DATEADD
            (
                DAY,
                -1 * (DATEDIFF(DAY, '19000105', @FechaOperacion) % 7),
                @FechaOperacion
            );

            ---------------------------------------------------
            -- Próximo viernes para asociaciones/desasociaciones
            ---------------------------------------------------

            SET @FechaInicioAplicacion = DATEADD
            (
                DAY,
                (7 - (DATEDIFF(DAY, '19000105', @FechaOperacion) % 7)) % 7,
                @FechaOperacion
            );

            SET @FechaFinAplicacion = DATEADD(DAY, -1, @FechaInicioAplicacion);

            ---------------------------------------------------
            -- 1. INSERTAR EMPLEADOS
            ---------------------------------------------------

            SELECT @IdOperacionActual = MIN(Id)
            FROM #Operaciones
            WHERE FechaOperacion = @FechaOperacion
              AND TipoOperacion = 'InsertarEmpleado';

            WHILE @IdOperacionActual IS NOT NULL
            BEGIN

                SELECT @Nodo = Nodo
                FROM #Operaciones
                WHERE Id = @IdOperacionActual;

                SELECT
                    @ValorDocumentoIdentidad = @Nodo.value('(/InsertarEmpleado/@ValorDocumentoIdentidad)[1]', 'INT'),
                    @Nombre = @Nodo.value('(/InsertarEmpleado/@Nombre)[1]', 'VARCHAR(128)'),
                    @NombrePuesto = @Nodo.value('(/InsertarEmpleado/@Puesto)[1]', 'VARCHAR(64)'),
                    @CuentaBancaria = @Nodo.value('(/InsertarEmpleado/@CuentaBancaria)[1]', 'VARCHAR(128)'),
                    @Username = @Nodo.value('(/InsertarEmpleado/@Username)[1]', 'VARCHAR(100)'),
                    @Pwd = @Nodo.value('(/InsertarEmpleado/@Password)[1]', 'VARCHAR(100)'),
                    @TipoUsuario = @Nodo.value('(/InsertarEmpleado/@TipoUsuario)[1]', 'INT'),
                    @FechaContratacion = @Nodo.value('(/InsertarEmpleado/@FechaContratacion)[1]', 'DATE');

                IF @TipoUsuario = 0
                BEGIN
                    SET @TipoUsuario = 2;
                END

                EXEC dbo.InsertarEmpleado
                    @ValorDocumentoIdentidad = @ValorDocumentoIdentidad,
                    @Nombre = @Nombre,
                    @NombrePuesto = @NombrePuesto,
                    @CuentaBancaria = @CuentaBancaria,
                    @Username = @Username,
                    @Password = @Pwd,
                    @TipoUsuario = @TipoUsuario,
                    @FechaContratacion = @FechaContratacion;

                SELECT @IdOperacionActual = MIN(Id)
                FROM #Operaciones
                WHERE FechaOperacion = @FechaOperacion
                  AND TipoOperacion = 'InsertarEmpleado'
                  AND Id > @IdOperacionActual;

            END

            ---------------------------------------------------
            -- 2. SI HAY ASISTENCIAS, ASEGURAR MES/SEMANA ACTUAL
            ---------------------------------------------------

            IF @CantidadAsistenciasFecha > 0
            BEGIN

                IF NOT EXISTS
                (
                    SELECT 1
                    FROM dbo.MesPlanilla
                    WHERE @FechaOperacion BETWEEN FechaInicio AND FechaFin
                )
                BEGIN

                    SET @PrimerDiaMes = DATEFROMPARTS
                    (
                        YEAR(@FechaOperacion),
                        MONTH(@FechaOperacion),
                        1
                    );

                    SET @PrimerViernesMes = DATEADD
                    (
                        DAY,
                        (7 - (DATEDIFF(DAY, '19000105', @PrimerDiaMes) % 7)) % 7,
                        @PrimerDiaMes
                    );

                    IF @FechaOperacion < @PrimerViernesMes
                    BEGIN

                        SET @PrimerDiaMesAnterior = DATEADD(MONTH, -1, @PrimerDiaMes);

                        SET @PrimerViernesMesAnterior = DATEADD
                        (
                            DAY,
                            (7 - (DATEDIFF(DAY, '19000105', @PrimerDiaMesAnterior) % 7)) % 7,
                            @PrimerDiaMesAnterior
                        );

                        SET @FechaInicioMes = @PrimerViernesMesAnterior;

                    END
                    ELSE
                    BEGIN
                        SET @FechaInicioMes = @PrimerViernesMes;
                    END

                    EXEC dbo.AbrirMesPlanilla
                        @FechaInicio = @FechaInicioMes;

                END

                IF NOT EXISTS
                (
                    SELECT 1
                    FROM dbo.SemanaPlanilla
                    WHERE @FechaOperacion BETWEEN FechaInicio AND FechaFin
                )
                BEGIN
                    EXEC dbo.AbrirSemanaPlanilla
                        @FechaInicio = @FechaInicioSemana;
                END

            END

            ---------------------------------------------------
            -- 3. MARCAR ASISTENCIAS
            -- Se asegura la semana usando la FECHA DE SALIDA
            ---------------------------------------------------

            SELECT @IdOperacionActual = MIN(Id)
            FROM #Operaciones
            WHERE FechaOperacion = @FechaOperacion
              AND TipoOperacion = 'MarcaAsistencia';

            WHILE @IdOperacionActual IS NOT NULL
            BEGIN

                SELECT @Nodo = Nodo
                FROM #Operaciones
                WHERE Id = @IdOperacionActual;

                SELECT
                    @ValorDocumentoIdentidad = @Nodo.value('(/MarcaAsistencia/@ValorDocumentoIdentidad)[1]', 'INT'),
                    @HoraEntrada = @Nodo.value('(/MarcaAsistencia/@HoraEntrada)[1]', 'DATETIME'),
                    @HoraSalida = @Nodo.value('(/MarcaAsistencia/@HoraSalida)[1]', 'DATETIME');

                SET @FechaPlanillaMarca = CONVERT(DATE, @HoraSalida);

                SET @FechaInicioSemanaMarca = DATEADD
                (
                    DAY,
                    -1 * (DATEDIFF(DAY, '19000105', @FechaPlanillaMarca) % 7),
                    @FechaPlanillaMarca
                );

                IF NOT EXISTS
                (
                    SELECT 1
                    FROM dbo.MesPlanilla
                    WHERE @FechaPlanillaMarca BETWEEN FechaInicio AND FechaFin
                )
                BEGIN

                    SET @PrimerDiaMes = DATEFROMPARTS
                    (
                        YEAR(@FechaPlanillaMarca),
                        MONTH(@FechaPlanillaMarca),
                        1
                    );

                    SET @PrimerViernesMes = DATEADD
                    (
                        DAY,
                        (7 - (DATEDIFF(DAY, '19000105', @PrimerDiaMes) % 7)) % 7,
                        @PrimerDiaMes
                    );

                    IF @FechaPlanillaMarca < @PrimerViernesMes
                    BEGIN

                        SET @PrimerDiaMesAnterior = DATEADD(MONTH, -1, @PrimerDiaMes);

                        SET @PrimerViernesMesAnterior = DATEADD
                        (
                            DAY,
                            (7 - (DATEDIFF(DAY, '19000105', @PrimerDiaMesAnterior) % 7)) % 7,
                            @PrimerDiaMesAnterior
                        );

                        SET @FechaInicioMes = @PrimerViernesMesAnterior;

                    END
                    ELSE
                    BEGIN
                        SET @FechaInicioMes = @PrimerViernesMes;
                    END

                    EXEC dbo.AbrirMesPlanilla
                        @FechaInicio = @FechaInicioMes;

                END

                IF NOT EXISTS
                (
                    SELECT 1
                    FROM dbo.SemanaPlanilla
                    WHERE @FechaPlanillaMarca BETWEEN FechaInicio AND FechaFin
                )
                BEGIN
                    EXEC dbo.AbrirSemanaPlanilla
                        @FechaInicio = @FechaInicioSemanaMarca;
                END

                EXEC dbo.MarcarAsistencia
                    @ValorDocumentoIdentidad = @ValorDocumentoIdentidad,
                    @HoraEntrada = @HoraEntrada,
                    @HoraSalida = @HoraSalida;

                SELECT @IdOperacionActual = MIN(Id)
                FROM #Operaciones
                WHERE FechaOperacion = @FechaOperacion
                  AND TipoOperacion = 'MarcaAsistencia'
                  AND Id > @IdOperacionActual;

            END

            ---------------------------------------------------
            -- 4. SI ES JUEVES, CERRAR SEMANA ACTUAL
            ---------------------------------------------------

            IF (DATEDIFF(DAY, '19000104', @FechaOperacion) % 7) = 0
            BEGIN

                IF EXISTS
                (
                    SELECT 1
                    FROM dbo.SemanaPlanilla
                    WHERE FechaInicio = @FechaInicioSemana
                )
                AND @CantidadAsistenciasFecha > 0
                BEGIN
                    EXEC dbo.CerrarSemanaPlanilla
                        @FechaInicioSemana = @FechaInicioSemana;
                END

            END

            ---------------------------------------------------
            -- 5. ASOCIAR DEDUCCIONES
            -- Aplican desde el próximo inicio de semana
            ---------------------------------------------------

            SELECT @IdOperacionActual = MIN(Id)
            FROM #Operaciones
            WHERE FechaOperacion = @FechaOperacion
              AND TipoOperacion = 'AsociaEmpleadoConDeduccion';

            WHILE @IdOperacionActual IS NOT NULL
            BEGIN

                SELECT @Nodo = Nodo
                FROM #Operaciones
                WHERE Id = @IdOperacionActual;

                SELECT
                    @ValorDocumentoIdentidad = @Nodo.value('(/AsociaEmpleadoConDeduccion/@ValorDocumentoIdentidad)[1]', 'INT'),
                    @TipoDeduccion = @Nodo.value('(/AsociaEmpleadoConDeduccion/@TipoDeduccion)[1]', 'VARCHAR(128)'),
                    @MontoFijo = @Nodo.value('(/AsociaEmpleadoConDeduccion/@MontoFijo)[1]', 'DECIMAL(18,2)');

                EXEC dbo.AsociarEmpleadoDeduccion
                    @ValorDocumentoIdentidad = @ValorDocumentoIdentidad,
                    @TipoDeduccion = @TipoDeduccion,
                    @MontoFijo = @MontoFijo,
                    @FechaInicio = @FechaInicioAplicacion;

                SELECT @IdOperacionActual = MIN(Id)
                FROM #Operaciones
                WHERE FechaOperacion = @FechaOperacion
                  AND TipoOperacion = 'AsociaEmpleadoConDeduccion'
                  AND Id > @IdOperacionActual;

            END

            ---------------------------------------------------
            -- 6. DESASOCIAR DEDUCCIONES
            -- Se ajusta FechaFin a la fecha antes del próximo viernes
            ---------------------------------------------------

            SELECT @IdOperacionActual = MIN(Id)
            FROM #Operaciones
            WHERE FechaOperacion = @FechaOperacion
              AND TipoOperacion = 'DesasociaEmpleadoConDeduccion';

            WHILE @IdOperacionActual IS NOT NULL
            BEGIN

                SELECT @Nodo = Nodo
                FROM #Operaciones
                WHERE Id = @IdOperacionActual;

                SELECT
                    @ValorDocumentoIdentidad = @Nodo.value('(/DesasociaEmpleadoConDeduccion/@ValorDocumentoIdentidad)[1]', 'INT'),
                    @TipoDeduccion = @Nodo.value('(/DesasociaEmpleadoConDeduccion/@TipoDeduccion)[1]', 'VARCHAR(128)');

                EXEC dbo.DesasociarEmpleadoDeduccion
                    @ValorDocumentoIdentidad = @ValorDocumentoIdentidad,
                    @TipoDeduccion = @TipoDeduccion;

                UPDATE ed
                SET ed.FechaFin = @FechaFinAplicacion
                FROM dbo.EmpleadoDeduccion AS ed
                INNER JOIN dbo.Empleado AS e
                    ON e.Id = ed.idEmpleado
                INNER JOIN dbo.TipoDeDeduccion AS td
                    ON td.Id = ed.idTipoDeduccion
                WHERE e.ValorDocumentoIdentidad = @ValorDocumentoIdentidad
                  AND td.Nombre = @TipoDeduccion
                  AND ed.FechaFin IS NOT NULL;

                SELECT @IdOperacionActual = MIN(Id)
                FROM #Operaciones
                WHERE FechaOperacion = @FechaOperacion
                  AND TipoOperacion = 'DesasociaEmpleadoConDeduccion'
                  AND Id > @IdOperacionActual;

            END

            ---------------------------------------------------
            -- 7. ASIGNAR JORNADAS
            -- Se hace antes de eliminar, por si el XML trae jornada
            -- para un empleado que termina esa semana.
            ---------------------------------------------------

            SELECT @IdOperacionActual = MIN(Id)
            FROM #Operaciones
            WHERE FechaOperacion = @FechaOperacion
              AND TipoOperacion = 'AsignarJornada';

            WHILE @IdOperacionActual IS NOT NULL
            BEGIN

                SELECT @Nodo = Nodo
                FROM #Operaciones
                WHERE Id = @IdOperacionActual;

                SELECT
                    @ValorDocumentoIdentidad = @Nodo.value('(/AsignarJornada/@ValorDocumentoIdentidad)[1]', 'INT'),
                    @Jornada = @Nodo.value('(/AsignarJornada/@Jornada)[1]', 'VARCHAR(100)'),
                    @InicioSemana = @Nodo.value('(/AsignarJornada/@InicioSemana)[1]', 'DATE');

                EXEC dbo.AsignarJornada
                    @ValorDocumentoIdentidad = @ValorDocumentoIdentidad,
                    @Jornada = @Jornada,
                    @InicioSemana = @InicioSemana;

                SELECT @IdOperacionActual = MIN(Id)
                FROM #Operaciones
                WHERE FechaOperacion = @FechaOperacion
                  AND TipoOperacion = 'AsignarJornada'
                  AND Id > @IdOperacionActual;

            END

            ---------------------------------------------------
            -- 8. ELIMINAR EMPLEADOS
            -- Se hace después de cerrar semana y antes de abrir
            -- la siguiente semana, para que no aparezcan activos.
            ---------------------------------------------------

            SELECT @IdOperacionActual = MIN(Id)
            FROM #Operaciones
            WHERE FechaOperacion = @FechaOperacion
              AND TipoOperacion = 'EliminarEmpleado';

            WHILE @IdOperacionActual IS NOT NULL
            BEGIN

                SELECT @Nodo = Nodo
                FROM #Operaciones
                WHERE Id = @IdOperacionActual;

                SELECT
                    @ValorDocumentoIdentidad = @Nodo.value('(/EliminarEmpleado/@ValorDocumentoIdentidad)[1]', 'INT');

                SELECT @IdEmpleadoOperacion = Id
                FROM dbo.Empleado
                WHERE ValorDocumentoIdentidad = @ValorDocumentoIdentidad;

                EXEC dbo.EliminarEmpleado
                    @ValorDocumentoIdentidad = @ValorDocumentoIdentidad;

                UPDATE dbo.EmpleadoDeduccion
                SET FechaFin = @FechaOperacion
                WHERE idEmpleado = @IdEmpleadoOperacion
                  AND FechaFin IS NOT NULL;

                DELETE pse
                FROM dbo.PlanillaSemanalEmpleado AS pse
                INNER JOIN dbo.SemanaPlanilla AS sp
                    ON sp.Id = pse.idSemanaPlanilla
                WHERE pse.IdEmpleado = @IdEmpleadoOperacion
                  AND sp.FechaInicio > @FechaOperacion
                  AND pse.SalarioBruto = 0
                  AND pse.TotalDeducciones = 0
                  AND pse.SalarioNeto = 0
                  AND pse.HorasOrdinarias = 0
                  AND pse.HorasExtra = 0
                  AND pse.HorasExtraDobles = 0;

                SELECT @IdOperacionActual = MIN(Id)
                FROM #Operaciones
                WHERE FechaOperacion = @FechaOperacion
                  AND TipoOperacion = 'EliminarEmpleado'
                  AND Id > @IdOperacionActual;

            END

            ---------------------------------------------------
            -- 9. SI ES JUEVES, ABRIR MES Y SEMANA SIGUIENTE
            ---------------------------------------------------

            IF (DATEDIFF(DAY, '19000104', @FechaOperacion) % 7) = 0
            BEGIN

                SET @FechaSiguiente = DATEADD(DAY, 1, @FechaOperacion);

                IF DAY(@FechaSiguiente) <= 7
                BEGIN

                    IF NOT EXISTS
                    (
                        SELECT 1
                        FROM dbo.MesPlanilla
                        WHERE @FechaSiguiente BETWEEN FechaInicio AND FechaFin
                    )
                    BEGIN
                        EXEC dbo.AbrirMesPlanilla
                            @FechaInicio = @FechaSiguiente;
                    END

                END

                IF NOT EXISTS
                (
                    SELECT 1
                    FROM dbo.SemanaPlanilla
                    WHERE FechaInicio = @FechaSiguiente
                )
                BEGIN
                    EXEC dbo.AbrirSemanaPlanilla
                        @FechaInicio = @FechaSiguiente;
                END

            END

            SET @IdFechaActual = @IdFechaActual + 1;

        END

        DROP TABLE #Fechas;
        DROP TABLE #Operaciones;

        SELECT 0 AS Resultado;

    END TRY
    BEGIN CATCH

        IF OBJECT_ID('tempdb..#Fechas') IS NOT NULL
            DROP TABLE #Fechas;

        IF OBJECT_ID('tempdb..#Operaciones') IS NOT NULL
            DROP TABLE #Operaciones;

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


