CREATE PROCEDURE dbo.DesasociarEmpleadoDeduccion
	@ValorDocumentoIdentidad INT,
	@TipoDeduccion VARCHAR(128)
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		DECLARE @IdEmpleado INT;
		DECLARE	@IdTipoDeduccion INT;

		BEGIN TRANSACTION

			SELECT	@IdEmpleado= e.Id
			FROM dbo.Empleado AS e
			WHERE e.ValorDocumentoIdentidad = @ValorDocumentoIdentidad

			SELECT	@IdTipoDeduccion= td.id
			FROM dbo.TipoDeDeduccion AS td
			WHERE td.Nombre = @TipoDeduccion

			IF @IdEmpleado IS NULL
			BEGIN 
				ROLLBACK;
				SELECT 50008 AS Resultado
				RETURN;
			END 

			IF @IdTipoDeduccion IS NULL
			BEGIN 
				ROLLBACK;
				SELECT 50008 AS Resultado
				RETURN;
			END

			UPDATE dbo.EmpleadoDeduccion
			SET Activa=0
			WHERE idEmpleado = @IdEmpleado AND idTipoDeduccion = @IdTipoDeduccion

		COMMIT;
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

