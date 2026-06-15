USE [tareaProgramada3]
GO

/****** Object:  StoredProcedure [dbo].[InsertarFeriado]    Script Date: 15/06/2026 10:59:33 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertarFeriado]
    @Id INT
    ,@Nombre VARCHAR(100)
    ,@Fecha DATE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        BEGIN TRANSACTION

        IF (@Nombre IS NULL OR @Nombre = '')
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END
        IF (@Fecha IS NULL)
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        IF EXISTS
        (
            SELECT 1
            FROM Feriado
            WHERE Id = @Id
        )
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        IF EXISTS
        (
            SELECT 1
            FROM Feriado
            WHERE Fecha = @Fecha
        )
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        INSERT INTO Feriado
        (
            Id,
            Nombre,
            Fecha
        )
        VALUES
        (
            @Id,
            @Nombre,
            @Fecha
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


