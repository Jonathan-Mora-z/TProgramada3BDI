CREATE PROCEDURE dbo.obtenerPlanillasMensuales
@Id INT
AS 
BEGIN 
	SELECT pme.SalarioBruto,
		   pme.TotalDeducciones,
		   pme.SalarioNeto
		   tde.Valor,
		   tde.Nombre
	FROM dbo.TipoDeDeduccion AS tde
		INNER JOIN MesPlanillaXDeduccion mpxd
			ON mpxd.idTipoDeduccion = tde.id
		INNER JOIN MesPlanilla mp
			ON mp.id= mpxd.idPlanillaMensual
		INNER JOIN PlanillaMensualEmpleado pme
			ON pme.IdMesPlanilla= mp.id
	WHERE pme.IdEmpleado=@Id
END

