USE [tareaProgramada3]
GO

/****** Object:  StoredProcedure [dbo].[CargarOperacionesXML]    Script Date: 17/06/2026 10:47:57 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[CargarOperacionesXML]
    @xml XML
AS
BEGIN

    SET NOCOUNT ON;

    BEGIN TRY

        CREATE TABLE #Operaciones
        (
            Id INT IDENTITY(1,1),
            TipoOperacion VARCHAR(100),
            Nodo XML
        );

        INSERT INTO #Operaciones
        (
            TipoOperacion,
            Nodo
        )
        SELECT
            T.N.value('local-name(.)','VARCHAR(100)'),
            T.N.query('.')
        FROM @xml.nodes('/Operaciones/FechaOperacion/*') T(N);

        DECLARE @IdActual INT = 1;
        DECLARE @MaxId INT;

        DECLARE @TipoOperacion VARCHAR(100);
        DECLARE @Nodo XML;

        SELECT @MaxId = MAX(Id)
        FROM #Operaciones;

        WHILE @IdActual <= ISNULL(@MaxId,0)
        BEGIN

            SELECT
                @TipoOperacion = TipoOperacion,
                @Nodo = Nodo
            FROM #Operaciones
            WHERE Id = @IdActual;

            IF @TipoOperacion = 'InsertarEmpleado'
            BEGIN

                DECLARE @ValorDocumentoIdentidad INT;
                DECLARE @Nombre VARCHAR(128);
                DECLARE @NombrePuesto VARCHAR(64);
                DECLARE @CuentaBancaria VARCHAR(128);
                DECLARE @Username VARCHAR(100);
                DECLARE @Pwd VARCHAR(100);
                DECLARE @TipoUsuario INT;
                DECLARE @FechaContratacion DATE;

                SELECT
                    @ValorDocumentoIdentidad = @Nodo.value('(/InsertarEmpleado/@ValorDocumentoIdentidad)[1]', 'INT'),
                    @Nombre = @Nodo.value('(/InsertarEmpleado/@Nombre)[1]', 'VARCHAR(128)'),
                    @NombrePuesto = @Nodo.value('(/InsertarEmpleado/@Puesto)[1]', 'VARCHAR(64)'),
                    @CuentaBancaria = @Nodo.value('(/InsertarEmpleado/@CuentaBancaria)[1]', 'VARCHAR(128)'),
                    @Username = @Nodo.value('(/InsertarEmpleado/@Username)[1]', 'VARCHAR(100)'),
                    @Pwd = @Nodo.value('(/InsertarEmpleado/@Password)[1]', 'VARCHAR(100)'),
                    @TipoUsuario = @Nodo.value('(/InsertarEmpleado/@TipoUsuario)[1]', 'INT'),
                    @FechaContratacion = @Nodo.value('(/InsertarEmpleado/@FechaContratacion)[1]', 'DATE');

                EXEC dbo.InsertarEmpleado
                    @ValorDocumentoIdentidad = @ValorDocumentoIdentidad,
                    @Nombre = @Nombre,
                    @NombrePuesto = @NombrePuesto,
                    @CuentaBancaria = @CuentaBancaria,
                    @Username = @Username,
                    @Password = @Pwd,
                    @TipoUsuario = @TipoUsuario,
                    @FechaContratacion = @FechaContratacion;
            END

            ELSE IF @TipoOperacion = 'AsociaEmpleadoConDeduccion'
            BEGIN

                DECLARE @ValorDocumentoIdentidadAD INT;
                DECLARE @TipoDeduccionAD VARCHAR(128);
                DECLARE @MontoFijo DECIMAL(18,2);

                SELECT
                    @ValorDocumentoIdentidadAD = @Nodo.value('(/AsociaEmpleadoConDeduccion/@ValorDocumentoIdentidad)[1]', 'INT'),
                    @TipoDeduccionAD = @Nodo.value('(/AsociaEmpleadoConDeduccion/@TipoDeduccion)[1]', 'VARCHAR(128)'),
                    @MontoFijo = @Nodo.value('(/AsociaEmpleadoConDeduccion/@MontoFijo)[1]', 'DECIMAL(18,2)');

                EXEC dbo.AsociarEmpleadoDeduccion
                    @ValorDocumentoIdentidad = @ValorDocumentoIdentidadAD,
                    @TipoDeduccion = @TipoDeduccionAD,
                    @MontoFijo = @MontoFijo;
            END

            ELSE IF @TipoOperacion = 'DesasociaEmpleadoConDeduccion'
            BEGIN

                DECLARE @ValorDocumentoIdentidadDD INT;
                DECLARE @TipoDeduccionDD VARCHAR(128);

                SELECT
                    @ValorDocumentoIdentidadDD = @Nodo.value('(/DesasociaEmpleadoConDeduccion/@ValorDocumentoIdentidad)[1]', 'INT'),
                    @TipoDeduccionDD = @Nodo.value('(/DesasociaEmpleadoConDeduccion/@TipoDeduccion)[1]', 'VARCHAR(128)');

                EXEC dbo.DesasociarEmpleadoDeduccion
                    @ValorDocumentoIdentidad = @ValorDocumentoIdentidadDD,
                    @TipoDeduccion = @TipoDeduccionDD;
            END


            ELSE IF @TipoOperacion = 'AsignarJornada'
            BEGIN

                DECLARE @ValorDocumentoIdentidadJ INT;
                DECLARE @Jornada VARCHAR(100);
                DECLARE @InicioSemana DATE;

                SELECT
                    @ValorDocumentoIdentidadJ = @Nodo.value('(/AsignarJornada/@ValorDocumentoIdentidad)[1]', 'INT'),
                    @Jornada = @Nodo.value('(/AsignarJornada/@Jornada)[1]', 'VARCHAR(100)'),
                    @InicioSemana = @Nodo.value('(/AsignarJornada/@InicioSemana)[1]', 'DATE');

                EXEC dbo.AsignarJornada
                    @ValorDocumentoIdentidad = @ValorDocumentoIdentidadJ,
                    @Jornada = @Jornada,
                    @InicioSemana = @InicioSemana;
            END

            ELSE IF @TipoOperacion = 'MarcaAsistencia'
            BEGIN

                DECLARE @ValorDocumentoIdentidadA INT;
                DECLARE @HoraEntrada DATETIME;
                DECLARE @HoraSalida DATETIME;

                SELECT
                    @ValorDocumentoIdentidadA = @Nodo.value('(/MarcaAsistencia/@ValorDocumentoIdentidad)[1]', 'INT'),
                    @HoraEntrada = @Nodo.value('(/MarcaAsistencia/@HoraEntrada)[1]', 'DATETIME'),
                    @HoraSalida = @Nodo.value('(/MarcaAsistencia/@HoraSalida)[1]', 'DATETIME');

                EXEC dbo.MarcarAsistencia
                    @ValorDocumentoIdentidad = @ValorDocumentoIdentidadA,
                    @HoraEntrada = @HoraEntrada,
                    @HoraSalida = @HoraSalida;
            END

            ELSE IF @TipoOperacion = 'EliminarEmpleado'
            BEGIN

                DECLARE @ValorDocumentoIdentidadE INT;

                SELECT
                    @ValorDocumentoIdentidadE = @Nodo.value('(/EliminarEmpleado/@ValorDocumentoIdentidad)[1]', 'INT');

                EXEC dbo.EliminarEmpleado
                    @ValorDocumentoIdentidad = @ValorDocumentoIdentidadE;
            END

            SET @IdActual = @IdActual + 1;

        END

        DROP TABLE #Operaciones;

        SELECT 0 AS Resultado;

    END TRY
    BEGIN CATCH

        IF OBJECT_ID('tempdb..#Operaciones') IS NOT NULL
            DROP TABLE #Operaciones;

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


