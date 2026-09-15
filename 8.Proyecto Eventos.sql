use proyectosql;

-- ==============================================================================
-- 08_EventosProgramados.sql
-- Automatización de tareas de mantenimiento y negocio
-- ==============================================================================
SET GLOBAL event_scheduler = ON;
-- ==============================================================================
-- DROPS
-- ==============================================================================

DROP EVENT IF EXISTS evt_generate_weekly_sales_report;
DROP EVENT IF EXISTS evt_cleanup_temp_tables_daily;
DROP EVENT IF EXISTS evt_archive_old_logs_monthly;
DROP EVENT IF EXISTS evt_deactivate_expired_promotions_hourly;
DROP EVENT IF EXISTS evt_recalculate_customer_loyalty_tiers_nightly;
DROP EVENT IF EXISTS evt_generate_reorder_list_daily;
DROP EVENT IF EXISTS evt_rebuild_indexes_weekly;
DROP EVENT IF EXISTS evt_suspend_inactive_accounts_quarterly;
DROP EVENT IF EXISTS evt_aggregate_daily_sales_data;
DROP EVENT IF EXISTS evt_check_data_consistency_nightly;


-- ==============================================================================
-- EJECUTABLES PREVIOS (Comentados para que no se ejecuten por accidente)
-- ==============================================================================

-- 8.1
DROP TABLE IF EXISTS reporte_ventas_semanales;
CREATE TABLE reporte_ventas_semanales (
    id_reporte INT AUTO_INCREMENT PRIMARY KEY,
    total_ventas DECIMAL(12,2) NOT NULL,
    cantidad_pedidos INT NOT NULL,
    fecha_generacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8.3
DROP TABLE IF EXISTS log_cambios_precio_historico;
CREATE TABLE IF NOT EXISTS log_cambios_precio_historico (
    id_historico INT AUTO_INCREMENT PRIMARY KEY,
    id_log_cambios_precio INT NOT NULL,
    id_producto INT NOT NULL,
    precio_viejo DECIMAL(10,2),
    precio_nuevo DECIMAL(10,2),
    fecha_log TIMESTAMP,
    fecha_archivado TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8.4
DROP TABLE IF EXISTS promociones;
CREATE TABLE promociones (
    id_promocion INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(50) NOT NULL UNIQUE,
    descuento DECIMAL(5,2) NOT NULL,
    fecha_expiracion DATETIME NOT NULL,
    activo BOOLEAN DEFAULT TRUE
);
INSERT INTO promociones (codigo, descuento, fecha_expiracion, activo) VALUES
('DESC10', 10.00, '2026-09-01 12:00:00', TRUE), 
('VERANO20', 20.00, '2026-10-15 23:59:59', TRUE), 
('FLASH50', 50.00, '2026-09-10 08:00:00', TRUE); 

-- 8.5
ALTER TABLE clientes ADD COLUMN nivel_lealtad VARCHAR(50);

-- 8.6
DROP TABLE IF EXISTS productos_reabastecer;
CREATE TABLE productos_reabastecer (
    id_productos_reabastecer INT AUTO_INCREMENT PRIMARY KEY,
    id_producto INT NOT NULL,
    nombre VARCHAR(150),
    stock_actual INT,
    stock_minimo INT,
    fecha_calculo TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

-- 8.8
ALTER TABLE clientes ADD COLUMN estado VARCHAR(20) DEFAULT 'ACTIVO';

-- 8.9
DROP TABLE IF EXISTS reporte_ventas_diarios;

CREATE TABLE reporte_ventas_diarios (
    id_reporte INT AUTO_INCREMENT PRIMARY KEY,
    total_ventas DECIMAL(12,2) NOT NULL,
    cantidad_pedidos INT NOT NULL,
    fecha_generacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8.10
DROP TABLE IF EXISTS log_inconsistencias;
CREATE TABLE log_inconsistencias (
    id_inconsistencia INT AUTO_INCREMENT PRIMARY KEY,
    descripcion VARCHAR(255) NOT NULL,
    fecha_deteccion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



-- ==============================================================================
-- EVENTOS
-- ==============================================================================

-- 8.1 evt_generate_weekly_sales_report: Genera un reporte de ventas semanal.
DELIMITER //

CREATE EVENT evt_generate_weekly_sales_report
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    DECLARE v_total DECIMAL(12,2);
    DECLARE v_cant INT;

    SELECT IFNULL(SUM(total), 0), COUNT(*) 
    INTO v_total, v_cant
    FROM ventas
    WHERE fecha_venta >= DATE_SUB(NOW(), INTERVAL 1 WEEK)
      AND estado != 'Cancelado';

    INSERT INTO reporte_ventas_semanales (total_ventas, cantidad_pedidos)
    VALUES (v_total, v_cant);
END //

-- 8.2 evt_cleanup_temp_tables_daily: Borra tablas temporales diariamente.
CREATE EVENT evt_cleanup_temp_tables_daily
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    TRUNCATE TABLE ventas_archivadas;
END //
 
-- 8.3 evt_archive_old_logs_monthly: Archiva logs de más de 6 meses en tablas históricas.
CREATE EVENT evt_archive_old_logs_monthly
ON SCHEDULE EVERY 1 MONTH
STARTS '2026-9-30 23:59:55' 
DO
BEGIN
	INSERT INTO log_cambios_precio_historico(id_log_cambios_precio,id_producto,precio_viejo,precio_nuevo,fecha_log)
	SELECT 
		 id_log_cambios_precio,
		 id_producto,
		 precio_viejo,
		 precio_nuevo,
		 fecha_log
    FROM log_cambios_precio
    WHERE fecha_log < DATE_SUB(NOW(), INTERVAL 6 MONTH);

	DELETE FROM log_cambios_precio WHERE fecha_log < DATE_SUB(NOW(), INTERVAL 6 MONTH);
END //
 
-- 8.4 evt_deactivate_expired_promotions_hourly: Desactiva códigos de descuento que han expirado.
CREATE EVENT evt_deactivate_expired_promotions_hourly
ON SCHEDULE EVERY 1 HOUR
STARTS CURDATE()
DO
BEGIN
	UPDATE promociones
	SET activo = FALSE
	WHERE fecha_expiracion <= NOW() AND activo = TRUE;
END //

-- 8.5 evt_recalculate_customer_loyalty_tiers_nightly: Recalcula el nivel de lealtad de los clientes cada noche.
CREATE EVENT evt_recalculate_customer_loyalty_tiers_nightly
ON SCHEDULE EVERY 1 DAY
STARTS '2026-9-15 22:00:00' 
DO
BEGIN
	UPDATE clientes
	SET nivel_lealtad = fn_DeterminarEstadoLealtad(id_cliente);
END; //

-- 8.6 evt_generate_reorder_list_daily: Crea una lista de productos que necesitan ser reabastecidos.
CREATE EVENT evt_generate_reorder_list_daily
ON SCHEDULE EVERY 1 DAY
STARTS '2026-9-15 20:00:00' 
DO
BEGIN
	INSERT INTO productos_reabastecer(id_producto,nombre,stock_actual,stock_minimo)
 	SELECT 
 		id_producto,
 		nombre,
 		stock,
 		100
 	FROM PRODUCTOS
 	WHERE stock < 100;
END //

-- 8.7 evt_rebuild_indexes_weekly: Reconstruye los índices de las tablas más usadas para optimizar el rendimiento.
CREATE EVENT evt_rebuild_indexes_weekly
ON SCHEDULE EVERY 1 WEEK
STARTS '2026-09-20 03:00:00'
DO
BEGIN
    OPTIMIZE TABLE productos, ventas, detalle_ventas, clientes, categorias, proveedores;
END //

-- 8.8 evt_suspend_inactive_accounts_quarterly: Desactiva cuentas de clientes sin actividad en más de un año.
CREATE EVENT evt_suspend_inactive_accounts_quarterly
ON SCHEDULE EVERY 3 MONTH
STARTS '2026-9-30 23:59:55'
DO
BEGIN
	UPDATE clientes
	SET estado = 'INACTIVO'
	WHERE TIMESTAMPDIFF(DAY,ultima_fecha_compra,CURDATE()) > 365 ;
END //

-- 8.9 evt_aggregate_daily_sales_data: Agrega los datos de ventas del día en una tabla de resumen para acelerar reportes.
CREATE EVENT evt_aggregate_daily_sales_data
ON SCHEDULE EVERY 1 DAY
STARTS '2026-09-14 00:00:01'
DO
BEGIN
    DECLARE v_total DECIMAL(12,2);
    DECLARE v_cant INT;

    SELECT IFNULL(SUM(total), 0),
    	   COUNT(*) 
    INTO v_total, v_cant
    FROM ventas
    WHERE fecha_venta >= DATE_SUB(NOW(), INTERVAL 1 DAY)
      AND estado != 'Cancelado';

    INSERT INTO reporte_ventas_diarios (total_ventas, cantidad_pedidos)
    VALUES (v_total, v_cant);
END //

-- 8.10 evt_check_data_consistency_nightly: Busca inconsistencias en los datos (ej. ventas sin detalles).
CREATE EVENT evt_check_data_consistency_nightly
ON SCHEDULE EVERY 1 DAY
STARTS '2026-09-15 03:00:00'
DO
BEGIN
    INSERT INTO log_inconsistencias (descripcion)
    SELECT CONCAT('Detalle de venta ID: ', dv.id_detalle, ' sin venta asociada.')
    FROM detalle_ventas dv
    LEFT JOIN ventas v ON dv.id_venta = v.id_venta
    WHERE v.id_venta IS NULL;
END //

DELIMITER ;