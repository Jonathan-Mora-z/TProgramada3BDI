USE [tareaProgramada3]
GO

/****** Object:  StoredProcedure [dbo].[CargarDatosXML]    Script Date: 18/06/2026 12:41:46 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CargarDatosXML]
    @Xml XML
AS
BEGIN

    SET NOCOUNT ON;

    BEGIN TRY

        BEGIN TRANSACTION

        INSERT INTO Error(Codigo, Descripcion)
        SELECT
            E.value('@Codigo','INT'),
            E.value('@Descripcion','VARCHAR(200)')
        FROM @Xml.nodes('/Datos/Error/error') T(E);

        INSERT INTO TiposdeEvento(Id, Nombre)
        SELECT
            E.value('@Id','INT'),
            E.value('@Nombre','VARCHAR(100)')
        FROM @Xml.nodes('/Datos/TiposEvento/TipoEvento') T(E);


        INSERT INTO Puesto(Nombre, SalarioXHora)
        SELECT
            P.value('@Nombre','VARCHAR(64)'),
            P.value('@SalarioXHora','REAL')
        FROM @Xml.nodes('/Datos/Puestos/Puesto') T(P);


        INSERT INTO TipoDeJornada
        (
            Id,
            Nombre,
            HoraInicio,
            HoraFin
        )
        SELECT
            J.value('@Id','INT'),
            J.value('@Nombre','VARCHAR(100)'),
            J.value('@HoraInicio','TIME'),
            J.value('@HoraFin','TIME')
        FROM @Xml.nodes('/Datos/TiposJornada/TipoJornada') T(J);


        INSERT INTO Feriado
        (
            Id,
            Nombre,
            Fecha
        )
        SELECT
            F.value('@Id','INT'),
            F.value('@Nombre','VARCHAR(100)'),
            F.value('@Fecha','DATE')
        FROM @Xml.nodes('/Datos/Feriados/Feriado') T(F);


        INSERT INTO TipoDeMovimiento
        (
            Id,
            Nombre,
            Acción
        )
        SELECT
            TM.value('@Id','INT'),
            TM.value('@Nombre','VARCHAR(100)'),
            TM.value('@Accion','CHAR(1)')
        FROM @Xml.nodes('/Datos/TiposMovimiento/TipoMovimiento') T(TM);


        INSERT INTO TipoDeDeduccion
        (
            Id,
            Nombre,
            Obligatorio,
            Porcentual,
            Valor,
            IdTipoMov
        )
        SELECT
            TD.value('@Id','INT'),
            TD.value('@Nombre','VARCHAR(100)'),
            TD.value('@EsObligatoria','BIT'),
            TD.value('@EsPorcentual','BIT'),
            TD.value('@Valor','REAL'),
            TM.Id
        FROM @Xml.nodes('/Datos/TiposDeduccion/TipoDeduccion') T(TD)

        INNER JOIN TipoDeMovimiento TM
            ON TM.Nombre =
               TD.value('@TipoMovimiento','VARCHAR(100)');


        INSERT INTO Usuario
        (
            Id,
            Username,
            Pwd,
            TipoUsuario
        )
        SELECT
            U.value('@Id','INT'),
            U.value('@Username','VARCHAR(100)'),
            U.value('@PasswordHash','VARCHAR(100)'),
            U.value('@Tipo','INT')
        FROM @Xml.nodes('/Datos/Usuarios/Usuario') T(U);

        COMMIT;

        SELECT 0 AS Resultado;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK;

        SELECT 50008 AS Resultado

    END CATCH

END
GO


