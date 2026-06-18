USE [tareaProgramada3]
GO

/****** Object:  StoredProcedure [dbo].[filtrarEmpleados]    Script Date: 17/06/2026 11:37:47 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[filtrarEmpleados]
    @Filtro VARCHAR(50)
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
        WHERE (
            @Filtro IS NULL 
            OR e.Nombre LIKE '%' + @Filtro + '%'
            OR CAST(e.ValorDocumentoIdentidad AS VARCHAR) LIKE '%' + @Filtro + '%'
        )

    END TRY
    BEGIN CATCH
        SELECT 50008 AS Resultado
    END CATCH

END
GO


