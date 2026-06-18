USE [tareaProgramada3]
GO

/****** Object:  StoredProcedure [dbo].[obtenerDatosSemanalesEmpleado]    Script Date: 17/06/2026 11:40:40 p. m. ******/
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
        mp.IdSemanalPlanilla,
        a.FechaEntrada,
        a.FechaSalida,

        SUM(CASE WHEN mh.TipoHora='Ordinario'
            THEN mh.CantidadHoras ELSE 0 END) AS HorasOrdinarias,

        SUM(CASE WHEN mh.TipoHora='Ordinario'
            THEN mp.Monto ELSE 0 END) AS MontoOrdinario,

        SUM(CASE WHEN mh.TipoHora='Extra Normal'
            THEN mh.CantidadHoras ELSE 0 END) AS HorasExtra,

        SUM(CASE WHEN mh.TipoHora='Extra Normal'
            THEN mp.Monto ELSE 0 END) AS MontoExtra,

        SUM(CASE WHEN mh.TipoHora='Extra Doble'
            THEN mh.CantidadHoras ELSE 0 END) AS HorasDobles,

        SUM(CASE WHEN mh.TipoHora='Extra Doble'
            THEN mp.Monto ELSE 0 END) AS MontoDoble

    FROM Asistencia a
    JOIN MovimientoHoras mh
        ON mh.IdAsistencia = a.Id
    JOIN MovimientoPlanilla mp
        ON mp.IdMovimientoHoras = mh.Id

    WHERE a.IdEmpleado = @id

    GROUP BY
        mp.IdSemanalPlanilla,
        a.Id,
        a.FechaEntrada,
        a.FechaSalida

    SELECT
        mp.idSemanalPlanilla,
        td.Nombre,
        CASE
            WHEN td.Porcentual = 1
            THEN td.Valor
            ELSE NULL
        END AS Porcentaje,
        mp.Monto
    FROM PlanillaSemanalEmpleado pse
        JOIN MovimientoPlanilla mp
            ON mp.idSemanalPlanilla = pse.idSemanaPlanilla
        JOIN MovimientoXDeduccion mxd
            ON mxd.idMovimientoPlanilla = mp.id
        JOIN TipoDeDeduccion td
            ON td.id = mxd.idTipoDeduccion
    WHERE pse.idEmpleado = @id
    ORDER BY
        mp.idSemanalPlanilla DESC,
        td.Nombre
END
GO


