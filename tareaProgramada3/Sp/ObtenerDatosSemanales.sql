USE [tareaProgramada3]
GO

/****** Object:  StoredProcedure [dbo].[obtenerDatosSemanalesEmpleado]    Script Date: 15/06/2026 11:01:27 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[obtenerDatosSemanalesEmpleado]
@id INT
AS
BEGIN
    SELECT p.SalarioBruto,
    p.TotalDeducciones,
    p.SalarioNeto,
    p.HorasOrdinarias,
    p.HorasExtra,
    p.HorasExtraDobles
    FROM dbo.PlanillaSemanalEmpleado AS p
    WHERE IdEmpleado=@id

	SELECT
    a.FechaEntrada,
    a.FechaSalida,
    mh.CantidadHoras,
    mp.Monto
    FROM Asistencia a
    INNER JOIN MovimientoHoras mh
        ON mh.idAsistencia = a.id
    INNER JOIN MovimientoPlanilla mp
        ON mp.idMovimientoHoras = mh.id
    WHERE a.idEmpleado = @id
    ORDER BY FechaEntrada DESC

END
GO


