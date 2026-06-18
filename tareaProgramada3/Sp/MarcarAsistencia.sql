USE [tareaProgramada3]
GO

/****** Object:  StoredProcedure [dbo].[MarcarAsistencia]    Script Date: 17/06/2026 11:40:25 p. m. ******/
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

		BEGIN TRANSACTION
		
		SELECT	@IdEmpleado= e.Id
		FROM dbo.Empleado AS e
		WHERE e.ValorDocumentoIdentidad = @ValorDocumentoIdentidad

		IF @IdEmpleado IS NULL
		BEGIN 
			ROLLBACK;
			SELECT 50008 AS Resultado
			RETURN;
		END 
		
		SELECT @IdAsistencia = ISNULL(MAX(id),0) + 1
        FROM dbo.Asistencia;

		INSERT INTO dbo.Asistencia (id, idEmpleado, FechaEntrada, FechaSalida)
		VALUES (@IdAsistencia, @IdEmpleado,@HoraEntrada,@HoraSalida)

		COMMIT;

		SELECT 0 AS Resultado

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


