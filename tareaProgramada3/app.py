from flask import Flask, redirect, render_template, request, session
import pyodbc
app = Flask(__name__)
app.secret_key = "S"
#---------Conexion a la base de datos---------
def conectarBD():
    return pyodbc.connect(
        "DRIVER={ODBC Driver 17 for SQL Server};"
        "SERVER=25.22.142.64;"
        "DATABASE=tareaProgramada3;"
        "UID=TDBD1;"
        "PWD=1234"
    )
#-------------Pagina de login----------------
@app.route("/", methods=["GET","POST"])
def Login():
    return render_template("loginTarea.html", deshabilitado=False)

@app.route("/login", methods=["POST"])
def procesarLogin():
    usuario = request.form["Username"]
    contraseña = request.form["Password"]
    ip = request.remote_addr
    BD=conectarBD()
    cursor=BD.cursor()
    cursor.execute("EXEC dbo.loginCompleto ?, ?, ?", (usuario, contraseña, ip))
    resultado = cursor.fetchone()
    tipo=resultado[3]
    IdUsuario = resultado[1]
    session["IdUsuario"] = IdUsuario
    BD.commit()
    BD.close()
    if tipo == "0":
        return render_template("paginaAdmin.html")
    else:
        return render_template("paginaEmpleado.html")
@app.route("/logout")
def logout():
    IdUsuario = session.get("IdUsuario")
    if IdUsuario:
        BD = conectarBD()
        cursor = BD.cursor()
        cursor.execute("EXEC dbo.registrarEnBitacora @IdTipoEvento=?, @Descripcion=?, @idUsuario=?, @PostInIp=?",
                       (4, "Logout", IdUsuario, request.remote_addr))
        BD.commit()
        BD.close()
    session.clear()
    return redirect("/")
# ----------Página principal HTML/Flask-------
@app.route("/principal")
def inicio():
    BD=conectarBD()
    cursor=BD.cursor()
    cursor.execute("EXEC dbo.consultarEmpleados")
    empleados = cursor.fetchall()
    cursor.execute("EXEC dbo.consultarPuestos")
    puestos = cursor.fetchall()
    BD.close()
    mensaje=session.pop("mensaje","")
    return render_template("browserTareaBD.html",empleados=empleados,puestos=puestos,mensaje=mensaje)
@app.route("/filtrar", methods=["GET","POST"])
def filtrar():
    filtro = request.form["filtro"]
    BD=conectarBD()
    cursor=BD.cursor()
    if not filtro or filtro.strip() == "":
        return redirect("/principal")
    if filtro.isalpha():
        tipo=11
        cursor.execute("EXEC dbo.obtenerTipoEvento @Id=?", (tipo,))
        evento=cursor.fetchone()[0]
    if filtro.isdigit():
        tipo=12
        cursor.execute("EXEC dbo.obtenerTipoEvento @Id=?", (tipo,))
        evento=cursor.fetchone()[0]
    cursor.execute(
            "EXEC dbo.registrarEnBitacora @IdTipoEvento=?, @Descripcion=?, @idUsuario=?, @PostInIp=?",
            (tipo, f"{evento}, Filtro: {filtro}", 
            session.get("IdUsuario"), request.remote_addr)
    )
    
    cursor.execute("EXEC dbo.filtrarEmpleados @Filtro=?", (filtro,))
    empleados = cursor.fetchall()
    cursor.execute("EXEC dbo.consultarPuestos")
    puestos = cursor.fetchall()
    BD.commit()
    BD.close()
    return render_template("browserTareaBD.html",empleados=empleados,puestos=puestos,mensaje=evento)
# Página del formulario
@app.route("/insertar")
def insertar():
    BD=conectarBD()
    cursor=BD.cursor()
    cursor.execute("EXEC dbo.consultarPuestos")
    puestos = cursor.fetchall()
    BD.close()
    return render_template("formulario.html",puestos=puestos)

@app.route("/eliminar", methods=["POST"])
def eliminar():
    id = request.form["empleado"]
    accion = request.form["accion"]
    BD=conectarBD()
    cursor=BD.cursor()
    if accion=="10":
        cursor.execute("EXEC dbo.eliminarEmpleado @IdEmpleado=?", (id,))
    cursor.execute("EXEC dbo.obtenerEmpleado @Id=?", (id,))
    datos = cursor.fetchone()
    cursor.execute("EXEC dbo.obtenerTipoEvento @Id=?", (int(accion),))
    evento = cursor.fetchone()[0]
    cursor.execute(
            "EXEC dbo.registrarEnBitacora @IdTipoEvento=?, @Descripcion=?, @idUsuario=?, @PostInIp=?",
            (accion, f"""{evento}, Documento Identidad: {datos[1]}, Nombre: {datos[2]}, Puesto: {datos[6]}
            Saldo Vacaciones: {datos[4]}""", 
            session.get("IdUsuario"), request.remote_addr)
        )
    session["mensaje"] = evento
    BD.commit()
    BD.close()
    return redirect("/principal")
    
@app.route("/actualizar", methods=["POST"])
def actualizar():
    id = request.form["empleado"]
    nombre=request.form["nombre"]
    docIden=request.form["documento"]
    puesto=request.form["puesto"]
    BD=conectarBD()
    cursor=BD.cursor()
    cursor.execute("""EXEC dbo.actualizarEmpleado @Id=?, @Nombre=?,@ValorDocIden=?,@IdPuesto=?""", (id,nombre,docIden,puesto))
    resultado = cursor.fetchone()
    if resultado is None:
        BD.close()
        return "Error: no se recibió resultado"
    codigo = resultado[0]
    cursor.execute("EXEC dbo.obtenerEmpleado @Id=?", (id,))
    datos = cursor.fetchone()
    if codigo != 0:
        cursor.execute("EXEC dbo.obtenerError @Codigo=?", (codigo,))
        error = cursor.fetchone()[0]
        cursor.execute(
            "EXEC dbo.registrarEnBitacora @IdTipoEvento=?, @Descripcion=?, @idUsuario=?, @PostInIp=?",
            (7, f"""{error}, Actuales: Documento Identidad: {datos[1]}, Nombre: {datos[2]}, Puesto: {datos[6]}
            Despues de editarse: Documento Identidad: {docIden}, Nombre: {nombre}, Puesto: {puesto}
            Saldo Vacaciones: {datos[4]}""", 
            session.get("IdUsuario"), request.remote_addr)
        )
        BD.commit()
        BD.close()
        session["mensaje"] = error
        return redirect("/principal")
    else:
        cursor.execute(
            "EXEC dbo.registrarEnBitacora @IdTipoEvento=?, @Descripcion=?, @idUsuario=?, @PostInIp=?",
            (8, f"""Update Exitoso, Actuales: Documento Identidad: {datos[1]}, Nombre: {datos[2]}, Puesto: {datos[6]}
            Despues de editarse: Documento Identidad: {docIden}, Nombre: {nombre}, Puesto: {puesto}
            Saldo Vacaciones: {datos[4]}""", 
            session.get("IdUsuario"), request.remote_addr)
        )
        BD.commit()
        BD.close()
        session["mensaje"] ="Update exitoso"
        return redirect("/principal")
# Procesar datos
@app.route("/procesar", methods=["POST"]) 
def procesar():
    nombre = request.form["nombre"]
    docIden = request.form["docIden"]
    puesto = request.form["puesto"]
    BD = conectarBD()
    cursor = BD.cursor()
    cursor.execute(
        "EXEC dbo.insertarEmpleado @IdPuesto=?, @ValorDocumentoIdentidad=?, @Nombre=?",
        (puesto, docIden, nombre)
    )
    resultado = cursor.fetchone()
    if resultado is None:
        BD.close()
        return "Error: no se recibió resultado"
    codigo = resultado[0]
    if codigo != 0:
        cursor.execute("EXEC dbo.obtenerError @Codigo=?", (codigo,))
        error = cursor.fetchone()[0]
        cursor.execute(
            "EXEC dbo.registrarEnBitacora @IdTipoEvento=?, @Descripcion=?, @idUsuario=?, @PostInIp=?",
            (5, f"{error}, Documento de identidad: {docIden} Nombre: {nombre}, Puesto: {puesto}", session.get("IdUsuario"), request.remote_addr)
        )
        BD.commit()
        BD.close()
        return render_template("formulario.html", mensaje=error)
    cursor.execute(
        "EXEC dbo.registrarEnBitacora @IdTipoEvento=?, @Descripcion=?, @idUsuario=?, @PostInIp=?",
        (6, f"Inserción exitosa, Documento de identidad: {docIden} Nombre: {nombre}, Puesto: {puesto}", session.get("IdUsuario"), request.remote_addr)
    )

    BD.commit()
    BD.close()
    return redirect("/principal")
@app.route("/movimientos",methods =["GET","POST"])
def movimientos():
    print("ENTRO")
    if request.method == "POST":
        id = request.form.get("empleado")
    else:
        id = request.args.get("id")
    BD = conectarBD()
    cursor = BD.cursor()

    cursor.execute("EXEC listarMovimientos ?", (id,))

    empleado = cursor.fetchone()

    cursor.nextset()
    movimientos = cursor.fetchall()
    mensaje = session.pop("mensaje", "")
    BD.close()

    return render_template(
        "movimientos.html",
        empleado=empleado,
        movimientos=movimientos,
        idEmpleado=id,mensaje=mensaje
    )

@app.route("/insertarMovimiento/<int:id>")
def insertar_movimiento(id):
    BD = conectarBD()
    cursor = BD.cursor()


    cursor.execute("EXEC dbo.consultarTiposMovimiento")
    tipos = cursor.fetchall()

    BD.close()

    return render_template("insertarMovimiento.html",
                           idEmpleado=id,
                           tipos=tipos)

@app.route("/guardarMovimiento", methods=["POST"])
def guardar_movimiento():
    IdEmpleado = request.form["IdEmpleado"]
    IdTipoMovimiento = request.form["IdTipoMovimiento"]
    Monto = request.form["Monto"]


    BD = conectarBD()
    cursor = BD.cursor()

    IdUsuario = session["IdUsuario"]
    IP = request.remote_addr
    cursor.execute("EXEC dbo.obtenerEmpleado @Id=?", (IdEmpleado,))
    empleado = cursor.fetchone()
    cursor.execute("EXEC dbo.obtenerTipoMovimiento @Id=?", (IdTipoMovimiento,))
    tipoMovimiento = cursor.fetchone()
    cursor.execute(
        "EXEC insertarMovimiento @IdEmpleado=?, @IdTipoMovimiento=?, @Monto=?, @IdUsuario=?, @PostInIP=?",
        (IdEmpleado, IdTipoMovimiento, Monto, IdUsuario, IP) 
    )
    codigo = cursor.fetchone()[0]
    if codigo != 0:
        cursor.execute("EXEC dbo.obtenerError @Codigo=?", (codigo,))
        error = cursor.fetchone()[0]
        cursor.execute(
            "EXEC dbo.registrarEnBitacora @IdTipoEvento=?, @Descripcion=?, @idUsuario=?, @PostInIp=?",
            (13, f"{error}, Documento de identidad: {empleado[1]}, Nombre: {empleado[2]}, Saldo Vacacionoes: {empleado[4]}, Tipo Movimiento: {tipoMovimiento}, Monto: {Monto}", IdUsuario, IP)
        )
        cursor.execute("EXEC dbo.obtenerTipoEvento @Id=?", (13,))
        evento = cursor.fetchone()[0]
        session["mensaje"] = evento
        BD.commit()
        BD.close()
        return redirect(f"/movimientos?id={IdEmpleado}")
    cursor.execute("EXEC dbo.obtenerTipoEvento @Id=?", (14,))
    evento = cursor.fetchone()[0]
    cursor.execute(
        "EXEC dbo.registrarEnBitacora @IdTipoEvento=?, @Descripcion=?, @idUsuario=?, @PostInIp=?",
        (14, f"{evento}, Documento de identidad: {empleado[1]}, Nombre: {empleado[2]}, Nuevo Saldo: {empleado[4]}, Tipo Movimiento: {tipoMovimiento}, Monto: {Monto}", IdUsuario, IP)
    )
    session["mensaje"] = evento
    BD.commit()
    BD.close()

    # volver a ver movimientos del mismo empleado
    return redirect(f"/movimientos?id={IdEmpleado}")
if __name__ == "__main__":
    app.run(debug=True)