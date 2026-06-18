USE [tareaProgramada3]
GO

/****** Object:  StoredProcedure [dbo].[obtenerEmpleadoPorId]    Script Date: 18/06/2026 12:47:05 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[obtenerEmpleadoPorId]
    @Id INT
AS
BEGIN
    SELECT  e.Id,
            e.IdUsuario,
            e.Nombre,
            e.ValorDocumentoIdentidad,
            e.FechaContratación,
            e.CuentaBancaria,
            e.EsActivo,
            p.Nombre AS Puesto
    FROM dbo.Empleado e
    INNER JOIN Puesto p ON e.IdPuesto = p.Id
    WHERE e.Id = @Id
END
GO


