CREATE PROCEDURE dbo.obtenerDatosSemanalesEmpleado
@id INT
AS
BEGIN
	DECLARE @IdSemana INT

	CREATE TABLE #Asistencias(
		IdAsistencia INT,
		FechaEntrada DATETIME,
		FechaSalida DATETIME)

	CREATE TABLE #MontosXHoras(
		HoraOrdinaria DECIMAL,
		HoraExtraNormalT DECIMAL,
		HoraExtraDoble DECIMAL)

	INSERT INTO #Asistencias
		SELECT a.id,a.FechaEntrada,a.FechaSalida
		FROM dbo.Asistencia AS a
	WHERE idEmpleado=@id


	SELECT p.SalarioBruto,p.TotalDeducciones,p.SalarioNeto,
		   p.HorasOrdinarias,p.HorasExtra,p.HorasExtraDobles
	FROM dbo.PlanillaSemanalEmpleado AS p
	WHERE IdEmpleado=@id
END 
		