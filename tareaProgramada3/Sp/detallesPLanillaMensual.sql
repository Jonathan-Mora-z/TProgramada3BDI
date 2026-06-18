USE [tareaProgramada3]
GO

/****** Object:  StoredProcedure [dbo].[detallesPLanillaMensual]    Script Date: 18/06/2026 12:44:12 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[detallesPLanillaMensual]
	@idMes INT,
	@idEmpleado INT
AS
BEGIN
	SELECT tde.Nombre,
		   tde.Porcentual,
		   mpxd.Monto
	FROM dbo.PlanillaMensualEmpleado AS pme
		INNER JOIN MesPlanillaXDeduccion mpxd
			ON mpxd.idPlanillaMensual=pme.idMesPlanilla
		INNER JOIN TipoDeDeduccion tde
			ON tde.id=mpxd.idTipoDeduccion
	WHERE pme.IdEmpleado=@idEmpleado AND idMesPlanilla=@idMes
END
GO


