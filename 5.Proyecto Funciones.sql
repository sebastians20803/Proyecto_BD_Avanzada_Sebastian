USE proyectosql;

-- ==============================================================================
-- 03_Funciones.sql
-- Funciones Definidas por el Usuario (UDFs) para lógica de negocio
-- ==============================================================================


-- ==============================================================================
-- DROPS DE FUNCIONES
-- ==============================================================================
DROP FUNCTION IF EXISTS fn_CalcularTotalVenta;
DROP FUNCTION IF EXISTS fn_VerificarDisponibilidadStock;
DROP FUNCTION IF EXISTS fn_ObtenerPrecioProducto;
DROP FUNCTION IF EXISTS fn_CalcularEdadCliente;
DROP FUNCTION IF EXISTS fn_FormatearNombreCompleto;
DROP FUNCTION IF EXISTS fn_EsClienteNuevo;
DROP FUNCTION IF EXISTS fn_CalcularCostoEnvio;
DROP FUNCTION IF EXISTS fn_AplicarDescuento;
DROP FUNCTION IF EXISTS fn_ObtenerUltimaFechaCompra;
DROP FUNCTION IF EXISTS fn_ValidarFormatoEmail;
DROP FUNCTION IF EXISTS fn_ObtenerNombreCategoria;
DROP FUNCTION IF EXISTS fn_ContarVentasCliente;
DROP FUNCTION IF EXISTS fn_CalcularDiasDesdeUltimaCompra;
DROP FUNCTION IF EXISTS fn_DeterminarEstadoLealtad;
DROP FUNCTION IF EXISTS fn_GenerarSKU;
DROP FUNCTION IF EXISTS fn_CalcularIVA;
DROP FUNCTION IF EXISTS fn_ObtenerStockTotalPorCategoria;
DROP FUNCTION IF EXISTS fn_EstimarFechaEntrega;
DROP FUNCTION IF EXISTS fn_ConvertirMonedaCOP;
DROP FUNCTION IF EXISTS fn_ValidarComplejidadContraseña;

-- EJECUTABLES

ALTER TABLE productos ADD COLUMN peso DECIMAL(10,2) DEFAULT 1.00; 



-- ==============================================================================
-- CREACIÓN DE FUNCIONES ALMACENADAS
-- ==============================================================================

DELIMITER //

-- 5.1 fn_CalcularTotalVenta: Calcula el monto total de una venta específica.
CREATE FUNCTION fn_CalcularTotalVenta(
	f_id_venta INT
)
RETURNS DECIMAL (10,2)
NOT DETERMINISTIC
READS SQL DATA
BEGIN
	DECLARE v_monto_total DECIMAL (10,2);
	SELECT SUM(dv.precio_unitario_congelado*dv.cantidad) INTO v_monto_total
	FROM detalle_ventas dv
	WHERE dv.id_venta = f_id_venta;

	RETURN v_monto_total;
END //

-- 5.2 fn_VerificarDisponibilidadStock: Valida si hay stock suficiente para un producto.
CREATE FUNCTION fn_VerificarDisponibilidadStock(
	f_id_producto INT,
	f_cantidad_requerida INT 
)
RETURNS BOOLEAN
NOT DETERMINISTIC 
READS SQL DATA
BEGIN
	DECLARE v_stock_actual INT;

	-- 1. Buscamos el stock actual
	SELECT stock INTO v_stock_actual
	FROM productos
	WHERE id_producto = f_id_producto; 
	
	-- 2. Evaluamos (Si el stock actual es mayor o igual al que pido, todo bien)
	IF v_stock_actual >= f_cantidad_requerida THEN
		RETURN TRUE;
	ELSE
		RETURN FALSE;
	END IF;
END //


-- 5.3 fn_ObtenerPrecioProducto: Devuelve el precio actual de un producto.
CREATE FUNCTION fn_ObtenerPrecioProducto(
    f_id_producto INT
)
RETURNS DECIMAL(10,2)
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE precio_actual DECIMAL(10,2);

    SELECT precio INTO precio_actual
    FROM productos
    WHERE id_producto = f_id_producto;

    RETURN IFNULL(precio_actual,0);
END //


-- 5.4 fn_CalcularEdadCliente: Calcula la edad de un cliente a partir de su fecha de nacimiento.
CREATE FUNCTION fn_CalcularEdadCliente(
    f_fecha_nacimiento DATE
)
RETURNS INT
NOT DETERMINISTIC
NO SQL
BEGIN
    DECLARE edad_cliente INT;

    SELECT TIMESTAMPDIFF(YEAR,f_fecha_nacimiento,CURDATE()) INTO edad_cliente;

    RETURN edad_cliente;
END //


-- 5.5 fn_FormatearNombreCompleto: Devuelve el nombre y apellido de un cliente en un formato estandarizado.
CREATE FUNCTION fn_FormatearNombreCompleto(
    f_id_cliente INT
)
RETURNS VARCHAR(100)
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_nombres VARCHAR(100);
    DECLARE v_apellidos VARCHAR(100);

    SELECT nombre,apellido INTO v_nombres,v_apellidos
    FROM clientes
    WHERE f_id_cliente = id_cliente;

    RETURN TRIM(CONCAT(v_nombres,' ',v_apellidos));
END //


-- 5.6 fn_EsClienteNuevo: Devuelve VERDADERO si un cliente realizó su primera compra en los últimos 30 días.
CREATE FUNCTION fn_EsClienteNuevo(
    f_id_cliente INT
)
RETURNS BOOLEAN
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_primera_compra DATE;

    SELECT MIN(fecha_venta) INTO v_primera_compra
    FROM ventas
    WHERE f_id_cliente = id_cliente
      AND estado != 'Cancelado';

    IF DATEDIFF(CURDATE(),v_primera_compra) <= 30 THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END //


-- 5.7 fn_CalcularCostoEnvio: Calcula el costo de envío basado en el peso total de los productos de una venta.

CREATE FUNCTION fn_CalcularCostoEnvio(
    f_id_venta INT
)
RETURNS DECIMAL(10,2)
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_peso_total DECIMAL(10,2);
    DECLARE v_costo_envio DECIMAL(10,2);

    SELECT SUM(dv.cantidad * p.peso) INTO v_peso_total
    FROM detalle_ventas dv
    INNER JOIN productos p ON dv.id_producto = p.id_producto
    INNER JOIN ventas v ON dv.id_venta = v.id_venta
    WHERE dv.id_venta = f_id_venta
      AND v.estado != 'Cancelado';

    IF v_peso_total IS NULL THEN
        RETURN 0.00;
    END IF;
    
    SET v_costo_envio = 5.00 + (v_peso_total * 2.50);

    RETURN v_costo_envio;
END //



-- 5.8 fn_AplicarDescuento: Aplica un porcentaje de descuento a un monto dado.
CREATE FUNCTION fn_AplicarDescuento(
    f_monto DECIMAL(10,2),
    f_descuento DECIMAL(10,2)
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
NO SQL
BEGIN
    IF f_descuento >= 0 AND f_descuento <= 100 THEN
        RETURN f_monto - (f_monto * f_descuento / 100);
    ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El descuento debe ser mayor o igual que 0 y menor o igual que 100';
    END IF;
END //


-- 5.9 fn_ObtenerUltimaFechaCompra: Devuelve la fecha de la última compra de un cliente.
CREATE FUNCTION fn_ObtenerUltimaFechaCompra(
    f_id_cliente INT
)
RETURNS DATE
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_ultima_compra DATE;

    SELECT MAX(fecha_venta) INTO v_ultima_compra
    FROM ventas
    WHERE f_id_cliente = id_cliente
      AND estado != 'Cancelado';

    RETURN v_ultima_compra;
END //


-- 5.10 fn_ValidarFormatoEmail: Comprueba si una cadena de texto tiene un formato de correo electrónico válido.
CREATE FUNCTION fn_ValidarFormatoEmail(
    v_correo_valido VARCHAR(100)
)
RETURNS BOOLEAN
DETERMINISTIC
NO SQL
BEGIN
    IF v_correo_valido REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END //


-- 5.11 fn_ObtenerNombreCategoria: Devuelve el nombre de la categoría a partir del ID de un producto.
CREATE FUNCTION fn_ObtenerNombreCategoria(
    v_id_producto INT
)
RETURNS VARCHAR(100)
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_nombre_categoria VARCHAR(100);

    SELECT c.nombre INTO v_nombre_categoria
    FROM categorias c
    INNER JOIN productos p ON p.id_categoria = c.id_categoria
    WHERE v_id_producto = p.id_producto;

    RETURN v_nombre_categoria;
END //


-- 5.12 fn_ContarVentasCliente: Cuenta el número total de compras realizadas por un cliente.
CREATE FUNCTION fn_ContarVentasCliente(
    v_id_cliente INT
)
RETURNS INT
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_cantidad_compras INT;

    SELECT COUNT(*) INTO v_cantidad_compras
    FROM ventas
    WHERE v_id_cliente = id_cliente
      AND estado != 'Cancelado';

    RETURN IFNULL(v_cantidad_compras,0);
END //


-- 5.13 fn_CalcularDiasDesdeUltimaCompra: Devuelve el número de días transcurridos desde la última compra de un cliente.
CREATE FUNCTION fn_CalcularDiasDesdeUltimaCompra(
    f_id_cliente INT
)
RETURNS INT
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_ultima_compra DATE;

    SELECT MAX(fecha_venta) INTO v_ultima_compra
    FROM ventas
    WHERE f_id_cliente = id_cliente
      AND estado != 'Cancelado';

    RETURN IFNULL(DATEDIFF(CURDATE(),v_ultima_compra),-1);
END //


-- 5.14 fn_DeterminarEstadoLealtad: Asigna un estado de lealtad (Bronce, Plata, Oro) a un cliente según su gasto total.
CREATE FUNCTION fn_DeterminarEstadoLealtad(
    f_id_cliente INT
)
RETURNS VARCHAR(10)
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_gasto_total DECIMAL(10,2);

    SELECT SUM(total) INTO v_gasto_total
    FROM ventas
    WHERE f_id_cliente = id_cliente
      AND estado != 'Cancelado';

    IF v_gasto_total > 5000 THEN
        RETURN 'Oro';
    ELSEIF v_gasto_total > 2000 THEN
        RETURN 'Plata';
    ELSE
        RETURN 'Bronce';
    END IF;
END //


-- 5.15 fn_GenerarSKU: Genera un código de producto (SKU) único basado en su nombre y categoría.
CREATE FUNCTION fn_GenerarSKU(
    f_id_producto INT
)
RETURNS VARCHAR(100)
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_nombre_producto VARCHAR(100);
    DECLARE v_nombre_categoria VARCHAR(100);

    SELECT p.nombre,c.nombre INTO v_nombre_producto,v_nombre_categoria
    FROM productos p
    INNER JOIN categorias c ON p.id_categoria = c.id_categoria
    WHERE f_id_producto = p.id_producto;

    SET v_nombre_producto = LEFT(v_nombre_producto,4);
    SET v_nombre_categoria = LEFT(v_nombre_categoria,3);

    RETURN UPPER(CONCAT(v_nombre_producto,'-',v_nombre_categoria,'-',f_id_producto));
END //


-- 5.16 fn_CalcularIVA: Calcula el impuesto (IVA) sobre el total de una venta.
CREATE FUNCTION fn_CalcularIVA(
    f_id_venta INT
)
RETURNS DECIMAL(10,2)
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(10,2);

    SELECT total INTO v_total
    FROM ventas
    WHERE f_id_venta = id_venta
      AND estado != 'Cancelado';

    RETURN v_total * 0.19;
END //


-- 5.17 fn_ObtenerStockTotalPorCategoria: Suma el stock de todos los productos de una categoría.
CREATE FUNCTION fn_ObtenerStockTotalPorCategoria(
    f_id_categoria INT
)
RETURNS INT
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_stock_total INT;

    SELECT SUM(stock) INTO v_stock_total
    FROM productos
    WHERE f_id_categoria = id_categoria;

    RETURN v_stock_total;
END //


-- 5.18 fn_EstimarFechaEntrega: Calcula la fecha estimada de entrega de un pedido según la ubicación del cliente.
CREATE FUNCTION fn_EstimarFechaEntrega(
    f_id_venta INT
)
RETURNS DATE
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_fecha_venta DATE;

    SELECT fecha_venta INTO v_fecha_venta
    FROM ventas
    WHERE f_id_venta = id_venta
      AND estado != 'Cancelado';

    RETURN DATE_ADD(v_fecha_venta,INTERVAL 5 DAY);
END //


-- 5.19 fn_ConvertirMonedaCOP: Convierte un monto a otra moneda usando una tasa de cambio fija.
CREATE FUNCTION fn_ConvertirMonedaCOP(
    f_monto DECIMAL(10,2)
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
NO SQL
BEGIN
    RETURN f_monto * 3123;
END //


-- 5.20 fn_ValidarComplejidadContraseña: Verifica si una contraseña cumple con los criterios de seguridad.
CREATE FUNCTION fn_ValidarComplejidadContraseña(
    v_contraseña VARCHAR(100)
)
RETURNS BOOLEAN
DETERMINISTIC
NO SQL
BEGIN
    IF REGEXP_LIKE(v_contraseña,'[a-z]')
       AND REGEXP_LIKE(v_contraseña,'[A-Z]')
       AND REGEXP_LIKE(v_contraseña,'[0-9]')
       AND REGEXP_LIKE(v_contraseña,'[^a-zA-Z0-9]')
       AND LENGTH(v_contraseña) >= 8 THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END //

DELIMITER ;


-- ==============================================================================
-- LLAMADAS DE PRUEBA (Comentadas para no alterar ejecución)
-- ==============================================================================
/*
SELECT fn_CalcularTotalVenta(3) AS monto_total;
SELECT fn_VerificarDisponibilidadStock(1, 30) AS hay_stock;
SELECT fn_ObtenerPrecioProducto(5) AS precio_actual;
SELECT fn_CalcularEdadCliente('2003-09-28') AS edad;
SELECT fn_FormatearNombreCompleto(1) AS nombre_completo;
SELECT fn_EsClienteNuevo(10) AS primera_compra_30_dias;
SELECT fn_CalcularCostoEnvio(2) AS costo_envio;
SELECT fn_AplicarDescuento(1000,200) AS monto_final;
SELECT fn_ObtenerUltimaFechaCompra(1) AS ultima_compra;
SELECT fn_ValidarFormatoEmail('sebastian@gmail.com') AS correo_valido;
SELECT fn_ObtenerNombreCategoria(5) AS nombre_categoria;
SELECT fn_ContarVentasCliente(1) AS cantidad_compras;
SELECT fn_CalcularDiasDesdeUltimaCompra(1) AS numero_dias_ultima_compra;
SELECT fn_DeterminarEstadoLealtad(4) AS lealtad_cliente;
SELECT fn_GenerarSKU(5) AS codigo_sku;
SELECT fn_CalcularIVA(1) AS monto_iva;
SELECT fn_ObtenerStockTotalPorCategoria(1) AS stock_total_categoria;
SELECT fn_EstimarFechaEntrega(1) AS fecha_entrega;
SELECT fn_ConvertirMonedaCOP(23) AS monto_convertido;
SELECT fn_ValidarComplejidadContraseña('Sebas123!') AS contraseña_valida;
*/