USE [tareaProgramada3]
GO

/****** Object:  StoredProcedure [dbo].[obtenerPlanillasSemanalesEmpleado]    Script Date: 18/06/2026 12:47:34 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[obtenerPlanillasSemanalesEmpleado]
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
END
GO


