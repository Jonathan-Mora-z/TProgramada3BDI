USE [tareaProgramada3]
GO

/****** Object:  StoredProcedure [dbo].[InsertarEmpleado]    Script Date: 18/06/2026 12:45:29 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertarEmpleado]
    @ValorDocumentoIdentidad INT,
    @Nombre VARCHAR(128),
    @NombrePuesto VARCHAR(64),
    @CuentaBancaria VARCHAR(128),
    @Username VARCHAR(100),
    @Password VARCHAR(100),
    @TipoUsuario VARCHAR(100),
    @FechaContratacion DATE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @IdPuesto INT;
        DECLARE @IdUsuario INT;

        BEGIN TRANSACTION;

        SELECT @IdPuesto = Id
        FROM Puesto
        WHERE Nombre = @NombrePuesto;

        IF @IdPuesto IS NULL
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        IF EXISTS
        (
            SELECT 1
            FROM Empleado
            WHERE ValorDocumentoIdentidad = @ValorDocumentoIdentidad
        )
        BEGIN
            ROLLBACK;
            SELECT 50004 AS Resultado;
            RETURN;
        END

        IF EXISTS
        (
            SELECT 1
            FROM Usuario
            WHERE Username = @Username
        )
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        SELECT @IdUsuario = ISNULL(MAX(Id),0) + 1
        FROM Usuario;

        INSERT INTO Usuario
        (
            Id,
            Username,
            Pwd,
            TipoUsuario
        )
        VALUES
        (
            @IdUsuario,
            @Username,
            @Password,
            @TipoUsuario
        );

        INSERT INTO Empleado
        (
            IdPuesto,
            IdUsuario,
            ValorDocumentoIdentidad,
            Nombre,
            CuentaBancaria,
            FechaContratación,
            EsActivo
        )
        VALUES
        (
            @IdPuesto,
            @IdUsuario,
            @ValorDocumentoIdentidad,
            @Nombre,
            @CuentaBancaria,
            @FechaContratacion,
            1
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


