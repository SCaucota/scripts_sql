-- -----------------------------------------------------
-- Creación de la BASE.
-- -----------------------------------------------------

CREATE SCHEMA IF NOT EXISTS harmonious;
USE harmonious;

-- -----------------------------------------------------
-- Creación de las TABLAS.
-- -----------------------------------------------------

-- --------Tabla PROFESIONAL ---------

CREATE TABLE IF NOT EXISTS  profesional(
	id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    genero ENUM('femenino', 'masculino', 'no binario') NOT NULL,
    dni INT UNIQUE NOT NULL,
    telefono VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    fecha_nacimiento DATE NOT NULL
);

-- --------Tabla ESPECIALIDAD ---------

CREATE TABLE IF NOT EXISTS  especialidad(
	id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    tipo VARCHAR(50) NOT NULL,
    descripcion VARCHAR(150) NOT NULL
);

-- --------Tabla HONORARIOS ---------

CREATE TABLE IF NOT EXISTS  honorario(
	id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, 
    descripcion VARCHAR(120) NOT NULL,
    monto DECIMAL(10,2) NOT NULL
);

-- --------Tabla ESPECIALIDAD-PROFESIONAL ---------

CREATE TABLE IF NOT EXISTS  especialidad_profesional(
	id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_profesional INT NOT NULL,
    id_especialidad INT NOT NULL,
    id_honorario INT NOT NULL,
    fecha_inicio DATE NOT NULL,
    FOREIGN KEY (id_profesional) REFERENCES profesional(id),
    FOREIGN KEY (id_especialidad) REFERENCES especialidad(id),
    FOREIGN KEY (id_honorario) REFERENCES honorario(id)
);

-- --------Tabla CLIENTE ---------

CREATE TABLE IF NOT EXISTS  cliente(
	id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, 
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    telefono VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    fecha_alta DATE NOT NULL
);

-- --------Tabla TRATAMIENTO ---------

CREATE TABLE IF NOT EXISTS  tratamiento(
	id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion VARCHAR(150) NOT NULL,
    precio DECIMAL(10,2) NOT NULL
);
-- --------Tabla TURNO ---------

CREATE TABLE IF NOT EXISTS  turno(
	id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, 
    id_profesional INT NOT NULL,
    id_especialidad INT NOT NULL,
    id_cliente INT NOT NULL,
    id_tratamiento INT NOT NULL,
	fecha DATE NOT NULL,
    hora TIME NOT NULL,
    total_abonado DECIMAL(10,2) NOT NULL,
    metodo_pago ENUM('efectivo', 'debito', 'transferencia') NOT NULL,
    estado ENUM('completado', 'pendiente') NOT NULL,
    FOREIGN KEY (id_profesional) REFERENCES profesional(id),
    FOREIGN KEY (id_especialidad) REFERENCES especialidad(id),
    FOREIGN KEY (id_cliente) REFERENCES cliente(id),
    FOREIGN KEY (id_tratamiento) REFERENCES tratamiento(id)
);
-- --------Tabla PRODUCTO ---------

CREATE TABLE IF NOT EXISTS  producto(
	id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, 
    nombre VARCHAR(100) NOT NULL,
    descripcion VARCHAR(150) NOT NULL,
    fecha_vencimiento DATE,
    cantidad_stock INT NOT NULL
);
-- --------Tabla PROVEEDOR ---------

CREATE TABLE IF NOT EXISTS proveedor(
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    contacto_telefono VARCHAR(50) NOT NULL,
    contacto_email VARCHAR(100),
    direccion VARCHAR(255)
);

-- --------Tabla ENTRADA_PRODUCTO ---------

CREATE TABLE IF NOT EXISTS entrada_producto(
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_producto INT NOT NULL,
    id_proveedor INT NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    cantidad_ingresada INT NOT NULL,
    fecha_ingreso DATE NOT NULL,
    FOREIGN KEY (id_producto) REFERENCES producto(id),
    FOREIGN KEY (id_proveedor) REFERENCES proveedor(id)
);

-- --------Tabla DETALLE_TURNO_PRODUCTO ---------

CREATE TABLE IF NOT EXISTS detalle_turno_producto(
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_turno INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad_producto_utilizado INT NOT NULL,
    FOREIGN KEY (id_turno) REFERENCES turno(id),
    FOREIGN KEY (id_producto) REFERENCES producto(id)
);

-- -------- Vistas ---------

CREATE OR REPLACE VIEW profesionales_experimentados AS
SELECT
    p.id AS id_profesional,
    CONCAT(p.nombre, ' ' , p.apellido) AS nombre_profesional,
    e.tipo AS tipo_especialidad,
    ep.id_honorario AS id_honorario,
    s.descripcion AS tipo_honorario
FROM profesional p
JOIN especialidad_profesional ep ON p.id = ep.id_profesional
JOIN especialidad e ON ep.id_especialidad = e.id
JOIN honorario s ON ep.id_honorario = s.id
WHERE s.id = 3
ORDER BY id_profesional ASC;

CREATE OR REPLACE VIEW turnos_efectivo AS
SELECT
    P.id AS id_profesional,
    CONCAT(p.nombre, ' ' , p.apellido) AS nombre_profesional,
    e.tipo AS tipo_especialidad,
    CONCAT(c.nombre, ' ' , c.apellido) AS nombre_cliente,
    ttr.nombre AS nombre_tratamiento,
    DATE_FORMAT(t.fecha, '%Y-%m-%d') AS fecha_turno,
    t.total_abonado,
    t.metodo_pago
FROM turno t
JOIN profesional p ON t.id_profesional = p.id
JOIN especialidad e ON t.id_especialidad = e.id
JOIN cliente c ON t.id_cliente = c.id
JOIN tratamiento ttr ON t.id_tratamiento = ttr.id
WHERE t.metodo_pago = 'efectivo';

CREATE OR REPLACE VIEW tratamientos_mas_solicitados AS
SELECT
    trt.id AS id_tratamiento,
    trt.nombre AS nombre_tratamiento,
    COUNT(*) AS veces_solicitado
FROM turno t
JOIN tratamiento trt ON t.id_tratamiento = trt.id
GROUP BY trt.id, trt.nombre
ORDER BY veces_solicitado DESC;

CREATE OR REPLACE VIEW edad_profesionales AS
SELECT
    p.id AS id_profesional,
    CONCAT(p.nombre, ' ', p.apellido) AS nombre_profesional,
    DATE_FORMAT(p.fecha_nacimiento, '%Y-%m-%d') AS fecha_nacimiento,
    YEAR(NOW()) - YEAR(p.fecha_nacimiento) - (DATE_FORMAT(NOW(), '00-%m-%d') < DATE_FORMAT(p.fecha_nacimiento, '00-%m-%d')) AS edad_actual
FROM profesional p
ORDER BY edad_actual DESC;


CREATE OR REPLACE VIEW cant_especialidad_profesional AS
SELECT
    p.id AS id_profesional,
    CONCAT(p.nombre, ' ', p.apellido) AS nombre_profesional,
    COUNT(*) AS cant_especialidades
FROM especialidad_profesional ep
JOIN profesional p ON ep.id_profesional = p.id
GROUP BY  1, 2
ORDER BY 3 DESC;

-- -------- FUNCIONES ---------

DELIMITER //
CREATE FUNCTION aniosTrabajandoProfesional(id_profesional INT)
RETURNS VARCHAR(50)
DETERMINISTIC
BEGIN
    DECLARE fechaActual DATE;
    DECLARE fechaInicioProfesional DATE;
    DECLARE anios INT;
    DECLARE meses INT;
    DECLARE dias INT;
    DECLARE diferencia VARCHAR(50);

    SET fechaActual = CURDATE();

    SELECT MIN(fecha_inicio)
    INTO fechaInicioProfesional
    FROM especialidad_profesional ep
    WHERE ep.id_profesional = id_profesional;

    SET anios = TIMESTAMPDIFF(YEAR, fechaInicioProfesional, fechaActual);
    SET fechaInicioProfesional = DATE_ADD(fechaInicioProfesional, INTERVAL anios YEAR);
    SET meses = TIMESTAMPDIFF(MONTH, fechaInicioProfesional, fechaActual);
    SET fechaInicioProfesional = DATE_ADD(fechaInicioProfesional, INTERVAL meses MONTH);
    SET dias = DATEDIFF(fechaActual, fechaInicioProfesional);

    SET diferencia = CONCAT(anios, ' años, ', meses, ' meses, ', dias, ' días');

    RETURN diferencia;
END//
DELIMITER ;

DELIMITER $$
CREATE FUNCTION ingresosAnualesEspecialidad(tipo_especialidad VARCHAR(50), anio INT)
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
    DECLARE resultado VARCHAR(255);
    DECLARE tipoEspecialidad VARCHAR(50);
    
    SET tipoEspecialidad = TRIM(tipo_especialidad);

    SELECT CONCAT(e.tipo, ': ',  '$',SUM(t.total_abonado), ' generados en el año ', anio)
    INTO resultado
    FROM turno t
    JOIN especialidad e ON t.id_especialidad = e.id
    WHERE e.tipo = tipoEspecialidad AND YEAR(t.fecha) = anio
    GROUP BY e.tipo;
    
	IF resultado IS NULL THEN
		SET resultado = CONCAT('No se han generado ingresos en el año ', anio);
	END IF;

    RETURN resultado;
END$$
DELIMITER ;

-- -------- STORE PROCEDURES ---------

/* Este Store Procedure permite ordenar la tabla profesional acorde a la columna y orden (ASC O DESC) especificados por los pramaetros de entrada.
Puede usarse esto para ponerlo a prueba: CALL OrdenarTablaProfesionales('nombre', 'ASC');*/

DELIMITER //
CREATE PROCEDURE OrdenarTablaProfesionales(
    IN columnaOrdenar VARCHAR(100),
    IN ordenClasificacion VARCHAR(10)
)
BEGIN
	
    SET @orden = '';
    SET columnaOrdenar = TRIM(columnaOrdenar);
    SET ordenClasificacion = TRIM(ordenClasificacion);
    
    IF columnaOrdenar IS NOT NULL  AND ordenClasificacion IS NOT NULL THEN
		SET @orden = CONCAT('ORDER BY  ', columnaOrdenar, ' ', ordenClasificacion);
	END IF;
    
    SET @clausula = CONCAT('SELECT * FROM profesional ', @orden);
    PREPARE ejecutar FROM @clausula;
    EXECUTE ejecutar;
    DEALLOCATE PREPARE ejecutar;
END //
DELIMITER ;

/*El Store Procedure nuevoTratamiento ejecuta la inserción de un nuevo tratamiento a la tabla tratamiento haciendo uso de parametros de entrada
Puede probarse con lo siguiente:
CALL nuevoTratamiento('Baño de CRema ', 'Uso de varios tipos de cremas en el cabello ', 3500.00 );
SELECT * FROM tratamiento;*/

DELIMITER //
 CREATE PROCEDURE nuevoTratamiento(
	IN nombreTratamiento VARCHAR(100),
	IN desTratamiento VARCHAR(150),
    IN precioTratamiento DECIMAL(10,2)
)
 BEGIN
	
    SET nombreTratamiento = TRIM(nombreTratamiento);
    SET desTratamiento = TRIM(desTratamiento);
    
	INSERT INTO tratamiento (nombre, descripcion, precio)
    VALUES (nombreTratamiento, desTratamiento, precioTratamiento);
 END //
 DELIMITER ;

/* El siguiente Store Procedure encuentra en la tabla especialidad_profesional a los profesionales que tienen más antigüedad (es decir, quien ha trabajado más tiempo en la peluquería) de acuerdo con la especialidad ingresada como parámetro de entrada (especialidad).
Puede usarse esto para probar el Store Procedure:
CALL profesionalAntiguoxEsp('Coloracion', @profesionalID, @nombreProfesional, @fecha_contratacion);
SELECT @profesionalID AS ProfesionalMasAntiguoID, @nombreProfesional AS nombreProfesional, @fecha_contratacion AS fecha_contratacion;*/

DELIMITER //
 CREATE PROCEDURE profesionalAntiguoxEsp(IN especialidad VARCHAR(50), OUT profesionalID INT, OUT nombreProfesional VARCHAR(100),OUT fecha_contratacion DATE)
 BEGIN
 
	SET especialidad = TRIM(especialidad);
 
	SELECT id_profesional, CONCAT(p.nombre, ' ', p.apellido), fecha_inicio
    INTO profesionalID, nombreProfesional,fecha_contratacion
    FROM especialidad_profesional ep
    JOIN especialidad e ON ep.id_especialidad = e.id
    JOIN profesional p ON ep.id_profesional = p.id
    WHERE e.tipo = especialidad
    ORDER BY fecha_inicio ASC
    LIMIT 1;
    
 END //
 DELIMITER ;
 
 
-- -------- TRIGGERS ---------

CREATE TABLE IF NOT EXISTS tratamiento_log (
	id_log INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_tratamiento INT NOT NULL,
    nombre_tratamiento VARCHAR(150) NOT NULL,
    usuario VARCHAR(150) NOT NULL,
    fecha_insercion DATE NOT NULL,
    hora_insercion TIME NOT NULL
);

/*Antes de insertar un tratamiento a la tabla, se verificará que no es haya agregado previamente uno con el mismo nombre. En caso de que exista uno se detendrá la inserción el sistema devolverá un mensaje de error.
Puede ponerse a prueba con esto:
INSERT INTO tratamiento (nombre, descripcion, precio) VALUES ('Alisado', 'Alisado temporal del cabello', 4500.00);

SELECT * FROM tratamiento WHERE nombre='Alisado';
SELECT * FROM tratamiento_log;
*/

DELIMITER $$
CREATE TRIGGER insercion_tratamiento_before
BEFORE INSERT ON tratamiento
FOR EACH ROW
BEGIN
	DECLARE tratamiento_count INT;

    SELECT COUNT(*) INTO tratamiento_count
    FROM tratamiento
    WHERE nombre = NEW.nombre;

    IF tratamiento_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede insertar el tratamiento. Ya existe un tratamiento con el mismo nombre.';
    END IF;
END $$
DELIMITER ;

/*Este trigger se encarga de registrar todos los nuevos tratamientos que se ingresan en la tabla. Los cambios se guardan en la tabla tratamiento_lod con la respectiva información de quien fue el usuario que realizó los cambios, además de la fecha y la hora en la que se produjo esa nueva inserción.*/

DELIMITER $$
CREATE TRIGGER insercion_tratamiento_after
AFTER INSERT ON tratamiento
FOR EACH ROW
BEGIN
	INSERT INTO tratamiento_log (id_tratamiento, nombre_tratamiento, usuario, fecha_insercion, hora_insercion)
    VALUES (NEW.id, NEW.nombre, USER(), CURDATE(), CURTIME());
END $$
DELIMITER ;


CREATE TABLE IF NOT EXISTS turno_precio_log (
	id_log INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	id_turno INT NOT NULL,
	usuario VARCHAR(150) NOT NULL,
    fecha_actual DATE NOT NULL,
    hora_actual TIME NOT NULL
);

/*En este trigger se verifica antes de hacer un insert que el total_abonado por el cliente sea igual al precio del tratamiento aplicado en ese turno, si es incorrecto y no coincide, se reemplaza el total_abonado por el precio de correspondiento al tratamiento de dicha tabla.
Los cambios se guardan en la tabla turno_precio_log para tener un registro de las inserciones erroneas que se han hecho en esa tabla.
Puede ponerse a prueba con esto:
INSERT INTO turno (id_profesional, id_especialidad, id_cliente, id_tratamiento, fecha, hora, total_abonado, metodo_pago) VALUES(5, 5, 8, 7, '2023-10-10', '10:30', 200.00, 'efectivo');

SELECT * FROM turno WHERE id = (SELECT MAX(id) FROM turno);
SELECT * FROM turno_precio_log;
*/

DELIMITER //
CREATE TRIGGER verificar_precio_turno
BEFORE INSERT ON turno
FOR EACH ROW
BEGIN
  DECLARE tratamiento_precio DECIMAL(10, 2);

  SELECT precio INTO tratamiento_precio
  FROM tratamiento
  WHERE id = NEW.id_tratamiento;

  IF NEW.total_abonado != tratamiento_precio THEN
    SET NEW.total_abonado = tratamiento_precio;
  END IF;
END;
//
DELIMITER ;

/*Luego de realizarse un insert, se registrará la inserción en la tabla turno_precio_log, en donde se podrá mantener un registro de la fila insertada, el usuario que lo realizó, además de la fecha y la hora en la que se llevó a cabo la acción*/;

DELIMITER //
CREATE TRIGGER registro_total_abonado_correcto
AFTER INSERT ON turno
FOR EACH ROW
BEGIN
    INSERT INTO turno_precio_log (id_turno, usuario, fecha_actual, hora_actual)
    VALUES (NEW.id, USER(), CURDATE(), CURTIME());
END;
//
DELIMITER ;