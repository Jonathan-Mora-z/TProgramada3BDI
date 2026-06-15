USE [tareaProgramada3]
GO

/****** Object:  StoredProcedure [dbo].[InsertarTipoJornada]    Script Date: 15/06/2026 11:00:42 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertarTipoJornada]
    @Id INT
    ,@Nombre VARCHAR(100)
    ,@HoraInicio TIME
    ,@HoraFin TIME
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

        IF EXISTS
        (
            SELECT 1
            FROM TipoDeJornada
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
            FROM TipoDeJornada
            WHERE Nombre = @Nombre
        )
        BEGIN
            ROLLBACK;
            SELECT 50008 AS Resultado;
            RETURN;
        END

        INSERT INTO TipoDeJornada
        (
            Id,
            Nombre,
            HoraInicio,
            HoraFin
        )
        VALUES
        (
            @Id,
            @Nombre,
            @HoraInicio,
            @HoraFin
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


