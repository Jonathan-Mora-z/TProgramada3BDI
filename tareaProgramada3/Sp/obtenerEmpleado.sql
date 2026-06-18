USE [tareaProgramada3]
GO

/****** Object:  StoredProcedure [dbo].[obtenerEmpleado]    Script Date: 18/06/2026 12:46:55 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[obtenerEmpleado]
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        SELECT 
            e.Id,
            e.Nombre,
            e.ValorDocumentoIdentidad,
            e.FechaContratación,
            e.CuentaBancaria,
            e.EsActivo,
            p.Nombre AS Puesto
        FROM dbo.Empleado e
        INNER JOIN Puesto p ON e.IdPuesto = p.Id
        WHERE (e.IdUsuario = @Id)

    END TRY
    BEGIN CATCH
        SELECT 50008 AS Resultado
    END CATCH

END
GO


