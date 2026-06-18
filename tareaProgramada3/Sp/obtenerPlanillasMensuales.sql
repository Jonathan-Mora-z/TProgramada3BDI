USE [tareaProgramada3]
GO

/****** Object:  StoredProcedure [dbo].[obtenerPlanillasMensuales]    Script Date: 17/06/2026 11:41:33 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[obtenerPlanillasMensuales]
@Id INT
AS 
BEGIN 
	SET LANGUAGE Spanish;

    SELECT
        pme.IdMesPlanilla,
        FORMAT(mp.FechaInicio, 'MMMM', 'es-es') AS Mes,
        YEAR(mp.FechaInicio) AS Anio,
        pme.SalarioBruto,
        pme.TotalDeducciones,
        pme.SalarioNeto
    FROM PlanillaMensualEmpleado pme
    INNER JOIN MesPlanilla mp
        ON mp.id = pme.IdMesPlanilla
    WHERE pme.IdEmpleado = @Id;

	SELECT mp.id AS idMesPlanilla,
		   tde.Nombre,
		   mpxd.Monto,
		   tde.Porcentual
	FROM dbo.TipoDeDeduccion AS tde
		INNER JOIN MesPlanillaXDeduccion mpxd
			ON mpxd.idTipoDeduccion = tde.id
		INNER JOIN MesPlanilla mp
			ON mp.id= mpxd.idPlanillaMensual
		INNER JOIN PlanillaMensualEmpleado pme
			ON pme.IdMesPlanilla= mp.id
	WHERE pme.IdEmpleado=@Id
END
GO


