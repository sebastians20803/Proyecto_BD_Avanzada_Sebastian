USE proyectosql;

-- 09_Procedimientos.sql

-- DROPS

DROP PROCEDURE IF EXISTS sp_RealizarNuevaVenta;
DROP PROCEDURE IF EXISTS sp_AgregarNuevoProducto;
DROP PROCEDURE IF EXISTS sp_ActualizarDireccionCliente;
DROP PROCEDURE IF EXISTS sp_ProcesarDevolucion;
DROP PROCEDURE IF EXISTS sp_ObtenerHistorialComprasCliente;
DROP PROCEDURE IF EXISTS sp_AjustarNivelStock;
DROP PROCEDURE IF EXISTS sp_EliminarClienteDeFormaSegura;
DROP PROCEDURE IF EXISTS sp_AplicarDescuentoPorCategoria;
DROP PROCEDURE IF EXISTS sp_GenerarReporteMensualVentas;
DROP PROCEDURE IF EXISTS sp_CambiarEstadoPedido;
DROP PROCEDURE IF EXISTS sp_RegistrarNuevoCliente;
DROP PROCEDURE IF EXISTS sp_ObtenerDetallesProductoCompleto;
DROP PROCEDURE IF EXISTS sp_FusionarCuentasCliente;
DROP PROCEDURE IF EXISTS sp_AsignarProductoAProveedor;
DROP PROCEDURE IF EXISTS sp_BuscarProductos;
DROP PROCEDURE IF EXISTS sp_ObtenerDashboardAdmin;
DROP PROCEDURE IF EXISTS sp_ProcesarPago;
DROP PROCEDURE IF EXISTS sp_AñadirReseñaProducto;
DROP PROCEDURE IF EXISTS sp_ObtenerProductosRelacionados;
DROP PROCEDURE IF EXISTS sp_MoverProductosEntreCategorias;

-- ------------------------------------------------------------------------------
-- CREACIÓN DE PROCEDIMIENTOS ALMACENADOS
-- ------------------------------------------------------------------------------

-- 9.1 sp_RealizarNuevaVenta: Procesa una nueva venta de forma transaccional.

CREATE PROCEDURE sp_RealizarNuevaVenta(
IN p_id_cliente INT,
IN p_id_producto INT,
IN p_cantidad INT
)
BEGIN
DECLARE v_id_venta INT;
DECLARE v_precio_actual DECIMAL(10,2);

DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
ROLLBACK;
SELECT 'Error en la transacción. Se deshicieron los cambios' AS Mensaje;
END;

START TRANSACTION;

INSERT INTO ventas (id_cliente, estado)
VALUES (p_id_cliente, 'Procesando');

-- 3. ¿Cómo sé qué ID de venta me acaba de generar MySQL?
-- La función LAST_INSERT_ID() atrapa el ID del último INSERT que acabamos de hacer.

SET v_id_venta = LAST_INSERT_ID();

-- 4. Buscamos el precio actual del producto en el catálogo
-- Lo necesitamos porque en Detalle_Ventas tú pusiste "precio_unitario_congelado"

SELECT precio INTO v_precio_actual
FROM productos
WHERE id_producto = p_id_producto;

-- 5. Agregamos el producto a la factura (Detalle_Venta)
INSERT INTO detalle_Ventas (id_venta, id_producto, cantidad, precio_unitario_congelado)
VALUES (v_id_venta, p_id_producto, p_cantidad, v_precio_actual);

-- 6. SI LLEGAMOS HASTA AQUÍ SIN ERRORES... ¡GUARDAR PERMANENTEMENTE!
COMMIT;

SELECT 'Venta registrada con éxito' AS Mensaje;

END;

CALL sp_RealizarNuevaVenta(1,21,5);

-- 9.2 sp_AgregarNuevoProducto: Inserta un nuevo producto y sus atributos iniciales.

CREATE PROCEDURE sp_AgregarNuevoProducto(
IN p_id_categoria INT,
IN p_id_proveedor INT,
IN p_nombre VARCHAR(150),
IN p_descripcion TEXT,
IN p_precio DECIMAL(10,2),
IN p_costo DECIMAL(10,2),
IN p_stock INT,
IN p_sku VARCHAR(50)
)
BEGIN
INSERT INTO productos(id_categoria,id_proveedor,nombre,descripcion,precio,costo,stock,sku)
VALUES (p_id_categoria,p_id_proveedor,p_nombre,p_descripcion,p_precio,p_costo,p_stock,p_sku);

SELECT 'Producto agregado exitosamente' AS Mensaje;
END;

CALL sp_AgregarNuevoProducto(1,1,'Iphone 18 Pro Max','Telefono ultimo modelo Apple',1300,800,35,'IPHO-TEC-21');

-- 9.3 sp_ActualizarDireccionCliente: Actualiza la dirección de un cliente en todas las tablas relevantes.

CREATE PROCEDURE sp_ActualizarDireccionCliente(
IN p_id_cliente INT,
IN p_nueva_direccion TEXT
)
BEGIN
UPDATE clientes
SET direccion_envio = p_nueva_direccion
WHERE id_cliente = p_id_cliente;

SELECT 'Dirección actualizada exitosamente' AS Mensaje;
END;

CALL sp_ActualizarDireccionCliente(1,'Calle 45#1-73, Bucaramanga');

-- 9.4 sp_ProcesarDevolucion: Gestiona la devolución de un producto, ajustando el stock y generando un crédito.

-- 9.5 sp_ObtenerHistorialComprasCliente: Devuelve el historial completo de compras de un cliente.

CREATE PROCEDURE sp_ObtenerHistorialComprasCliente(
IN p_id_cliente INT
)
BEGIN
SELECT
v.id_venta,
v.fecha_venta,
p.nombre AS producto,
dv.cantidad,
dv.precio_unitario_congelado,
v.estado
FROM ventas v
INNER JOIN detalle_ventas dv ON v.id_venta = dv.id_venta
INNER JOIN productos p ON dv.id_producto = p.id_producto
WHERE v.id_cliente = p_id_cliente
ORDER BY v.fecha_venta DESC;

END;

CALL sp_ObtenerHistorialComprasCliente(1);

-- 9.6 sp_AjustarNivelStock: Permite ajustar manualmente el stock de un producto, registrando el motivo.

CREATE TABLE ajustes_stock (
id_ajuste INT AUTO_INCREMENT PRIMARY KEY,
id_producto INT NOT NULL,
stock_anterior INT NOT NULL, -- <--- NUEVO
stock_nuevo INT NOT NULL, -- <--- NUEVO
motivo VARCHAR(255) NOT NULL,
fecha_ajuste TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

CREATE PROCEDURE sp_AjustarNivelStock(
IN p_id_producto INT,
IN p_nuevo_stock INT,
IN p_motivo VARCHAR(255)
)
BEGIN
DECLARE v_stock_anterior INT;

DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
ROLLBACK;
SELECT 'Error en la transacción. Se deshicieron los cambios' AS Mensaje;
END;

START TRANSACTION;

SELECT stock INTO v_stock_anterior
FROM productos
WHERE id_producto = p_id_producto;

UPDATE productos
SET stock = p_nuevo_stock
WHERE id_producto = p_id_producto;

INSERT INTO ajustes_stock(id_producto,stock_anterior,stock_nuevo,motivo)
VALUES (p_id_producto,v_stock_anterior,p_nuevo_stock,p_motivo);

COMMIT;

SELECT 'Stock modificado con éxito' AS Mensaje;

END;

CALL sp_AjustarNivelStock(1,60,'Compra barata en TEMU');

-- 9.7 sp_EliminarClienteDeFormaSegura: Anonimiza los datos de un cliente en lugar de borrarlos, para mantener la integridad referencial.

CREATE PROCEDURE sp_EliminarClienteDeFormaSegura(
IN p_id_cliente INT
)
BEGIN

UPDATE clientes
SET nombre = 'Anonimo',
apellido = 'Anonimo',
email = CONCAT('eliminado_', p_id_cliente, '@anon.com')
WHERE p_id_cliente = id_cliente;

END;

CALL sp_EliminarClienteDeFormaSegura(10);

-- 9.8 sp_AplicarDescuentoPorCategoria: Aplica un descuento a todos los productos de una categoría específica.

CREATE PROCEDURE sp_AplicarDescuentoPorCategoria(
IN p_id_categoria INT,
IN p_descuento DECIMAL(4,2)
)

BEGIN

UPDATE productos
SET precio = precio - (precio * (p_descuento / 100))
WHERE id_categoria = p_id_categoria;

SELECT CONCAT('Se aplicó un ', p_descuento, '% de descuento a la categoría ', p_id_categoria) AS Mensaje;

END;

CALL sp_AplicarDescuentoPorCategoria(1,10);

-- 9.9 sp_GenerarReporteMensualVentas: Genera un reporte completo de ventas para un mes y año dados.

CREATE PROCEDURE sp_GenerarReporteMensualVentas(
IN p_mes INT,
IN p_anio INT
)

BEGIN

SELECT
v.id_venta,
c.nombre,
v.estado,
v.total,
v.fecha_venta
FROM ventas v
INNER JOIN clientes c ON c.id_cliente = v.id_cliente
WHERE MONTH(fecha_venta) = p_mes AND YEAR(fecha_venta) = p_anio;

END;

CALL sp_GenerarReporteMensualVentas(08,2026);

-- 9.10 sp_CambiarEstadoPedido: Cambia el estado de un pedido (ej. 'Procesando' a 'Enviado') y notifica a otros sistemas.

CREATE PROCEDURE sp_CambiarEstadoPedido(
IN p_id_venta INT,
IN p_estado_nuevo VARCHAR(20)
)

BEGIN

UPDATE ventas
SET estado = p_estado_nuevo
WHERE id_venta = p_id_venta ;

SELECT CONCAT('El estado del pedido ', p_id_venta, ' cambió a: ', p_estado_nuevo) AS Mensaje;

END;

CALL sp_CambiarEstadoPedido(12,'Entregado');

-- 9.11 sp_RegistrarNuevoCliente: Registra un nuevo cliente validando que el email no exista.

CREATE PROCEDURE sp_RegistrarNuevoCliente(
IN p_nombre VARCHAR(100),
IN p_apellido VARCHAR(100),
IN p_email VARCHAR(100),
IN p_contrasena VARCHAR(100),
IN p_direccion_envio TEXT
)

BEGIN

IF EXISTS (SELECT 1 FROM clientes WHERE email = p_email) THEN
SELECT 'Error: El correo electrónico ya se encuentra registrado.' AS Mensaje;

ELSE

INSERT INTO clientes(nombre,apellido,email,contraseña,direccion_envio)
VALUES (p_nombre,p_apellido,p_email,p_contrasena,p_direccion_envio);

SELECT 'Cliente registrado exitosamente.' AS Mensaje;
END IF;
END;

CALL sp_RegistrarNuevoCliente('Sebastian','Sierra','sebastian@gmail.com','hash_pwd_11','Calle 45#1-73');

-- 9.12 sp_ObtenerDetallesProductoCompleto: Devuelve toda la información de un producto,
-- incluyendo datos de su proveedor y categoría.

CREATE PROCEDURE sp_ObtenerDetallesProductoCompleto(
IN p_id_producto INT
)

BEGIN

SELECT
p.nombre as producto,
c.nombre as categoria,
pr.nombre as proveedores,
p.precio,
p.costo,
p.stock,
p.sku
FROM productos p
INNER JOIN categorias c ON p.id_categoria = c.id_categoria
INNER JOIN proveedores pr ON p.id_proveedor = pr.id_proveedor
WHERE p_id_producto = p.id_producto;

END;

CALL sp_ObtenerDetallesProductoCompleto(1);

-- 9.13 sp_FusionarCuentasCliente: Fusiona dos cuentas de cliente duplicadas en una sola.

CREATE PROCEDURE sp_FusionarCuentasCliente(
IN p_id_cliente_viejo INT,
IN p_id_cliente_nuevo INT
)
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
ROLLBACK;
SELECT 'Error al fusionar las cuentas. Cambios revertidos.' AS Mensaje;
END;

START TRANSACTION;

UPDATE ventas
SET id_cliente= p_id_cliente_nuevo
WHERE id_cliente = p_id_cliente_viejo;

DELETE FROM clientes WHERE id_cliente = p_id_cliente_viejo;

COMMIT;

SELECT 'Cuentas fusionadas con éxito' AS Mensaje;
END;

-- 9.14 sp_AsignarProductoAProveedor: Asigna o cambia el proveedor de un producto.

CREATE PROCEDURE sp_AsignarProductoAProveedor(
IN p_id_producto INT,
IN p_id_proveedor INT
)
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
ROLLBACK;
SELECT 'Error al cambiar/asignar proveedor a producto.' AS Mensaje;
END;

START TRANSACTION;

UPDATE productos
SET id_proveedor= p_id_proveedor
WHERE id_producto = p_id_producto;

COMMIT;

SELECT 'Proveedor cambiado con exito! ' AS Mensaje;
END;

CALL sp_AsignarProductoAProveedor(18,1);

-- 9.15 sp_BuscarProductos: Realiza una búsqueda avanzada de productos con filtros por nombre, categoría, rango de precios, etc.

CREATE PROCEDURE sp_BuscarProductos(
IN p_opcion INT, -- 1 = Buscar por nombre, 2 = Buscar por categoría
IN p_texto_busqueda VARCHAR(150),
IN p_precio_min DECIMAL(10,2),
IN p_precio_max DECIMAL(10,2)
)
BEGIN
IF p_opcion = 1 THEN
SELECT id_producto, nombre, precio, stock
FROM productos
WHERE nombre LIKE CONCAT('%', p_texto_busqueda, '%')
AND precio >= p_precio_min
AND precio <= p_precio_max;

ELSEIF p_opcion = 2 THEN
SELECT
p.id_producto,
c.nombre as categoria,
p.nombre as producto,
p.precio,
p.stock
FROM productos p
INNER JOIN categorias c ON p.id_categoria = c.id_categoria
WHERE c.nombre LIKE CONCAT('%', p_texto_busqueda, '%')
AND precio >= p_precio_min
AND precio <= p_precio_max;
ELSE
SELECT 'Error: Debe elegir 1 para filtrar por nombre o 2 por categoria' AS Mensaje;
END IF;
END;

CALL sp_BuscarProductos(2,'Laptop',1,2000);

-- 9.16 sp_ObtenerDashboardAdmin: Devuelve un conjunto de KPIs para un panel de administración.

CREATE PROCEDURE sp_ObtenerDashboardAdmin()

BEGIN
SELECT
(SELECT COUNT(*) FROM clientes) AS total_clientes,
(SELECT COUNT(*) FROM productos WHERE stock > 0) AS productos_activos,
(SELECT SUM(total)FROM ventas WHERE estado = 'Entregado') AS ventas_totales;
END;

CALL sp_ObtenerDashboardAdmin();

-- 9.17 sp_ProcesarPago: Simula el procesamiento de un pago para una venta, actualizando su estado a "Pagado".

CREATE PROCEDURE sp_ProcesarPago(
IN p_id_venta INT
)

BEGIN
DECLARE v_estado_actual VARCHAR(30);

SELECT estado INTO v_estado_actual
FROM ventas
WHERE id_venta = p_id_venta;

IF v_estado_actual = 'Pendiente de Pago' THEN
UPDATE ventas
SET estado = 'Procesando'
WHERE id_venta = p_id_venta ;
SELECT CONCAT('Pago procesado para la venta: ', p_id_venta) AS Mensaje;

ELSE
SELECT CONCAT('El estado de la venta es:',' ',v_estado_actual,'. ','y debe ser Pendiente de Pago') AS Mensaje;
END IF;

END;

CALL sp_ProcesarPago(15);

-- 9.18 sp_AñadirReseñaProducto: Permite a un cliente añadir una reseña y calificación a un producto que ha comprado.

DROP TABLE IF EXISTS resenas;

CREATE TABLE resenas (
id_resena INT AUTO_INCREMENT PRIMARY KEY,
id_producto INT NOT NULL,
id_cliente INT NOT NULL,
calificacion INT NOT NULL CHECK (calificacion >= 1 AND calificacion <= 5),
comentario TEXT,
fecha_resena TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
FOREIGN KEY (id_producto) REFERENCES productos(id_producto),
FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);

CREATE PROCEDURE sp_AñadirReseñaProducto(
IN p_id_cliente INT,
IN p_id_producto INT,
IN p_calificacion INT,
IN p_comentario TEXT
)

BEGIN
IF EXISTS (
SELECT 1
FROM ventas v
INNER JOIN detalle_ventas dv ON v.id_venta = dv.id_venta
WHERE v.id_cliente = p_id_cliente AND dv.id_producto = p_id_producto
) THEN
INSERT INTO resenas(id_producto,id_cliente,calificacion,comentario)
VALUES (p_id_producto,p_id_cliente,p_calificacion,p_comentario);

SELECT 'Reseña añadida con éxito' AS Mensaje;
ELSE
SELECT 'Error: No puedes reseñar un producto que no has comprado.' AS Mensaje;
END IF;

END;

-- 9.19 sp_ObtenerProductosRelacionados: Devuelve una lista de productos relacionados a uno dado, basándose en compras de otros clientes.

CREATE PROCEDURE sp_ObtenerProductosRelacionados(
IN p_id_producto INT
)
BEGIN
SELECT DISTINCT p.nombre AS producto_recomendado,
p.precio
FROM detalle_ventas dv1
INNER JOIN detalle_ventas dv2 ON dv1.id_venta = dv2.id_venta
INNER JOIN productos p ON dv2.id_producto = p.id_producto
WHERE dv1.id_producto = p_id_producto
AND dv2.id_producto != p_id_producto; -- Evitamos recomendar el mismo producto que ya estamos viendo
END;

CALL sp_ObtenerProductosRelacionados(3);

-- 9.20 sp_MoverProductosEntreCategorias: Mueve uno o más productos de una categoría a otra de forma segura.

CREATE PROCEDURE sp_MoverProductosEntreCategorias(
IN p_id_producto INT,
IN p_nueva_categoria INT
)
BEGIN
UPDATE productos
SET id_categoria = p_nueva_categoria
WHERE id_producto = p_id_producto;

SELECT 'Nueva categoria asignada correctamente! ' AS Mensaje;

END;