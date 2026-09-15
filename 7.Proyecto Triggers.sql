USE proyectosql;

-- ==============================================================================
-- 7_Triggers.sql
-- Disparadores para auditoría, validaciones y automatización en tiempo real
-- ==============================================================================

-- ==============================================================================
-- DROPS DE TRIGGERS
-- ==============================================================================
DROP TRIGGER IF EXISTS trg_audit_precio_producto_after_update;
DROP TRIGGER IF EXISTS trg_check_stock_before_insert_venta;
DROP TRIGGER IF EXISTS trg_update_stock_after_insert_venta;
DROP TRIGGER IF EXISTS trg_prevent_delete_categoria_with_products;
DROP TRIGGER IF EXISTS trg_log_new_customer_after_insert;
DROP TRIGGER IF EXISTS trg_update_total_gastado_cliente;
DROP TRIGGER IF EXISTS trg_set_fecha_modificacion_producto;
DROP TRIGGER IF EXISTS trg_prevent_negative_stock;
DROP TRIGGER IF EXISTS trg_capitalize_nombre_cliente;
DROP TRIGGER IF EXISTS trg_recalculate_total_venta_on_detalle_change;
DROP TRIGGER IF EXISTS trg_log_order_status_change;
DROP TRIGGER IF EXISTS trg_prevent_price_zero_or_less;
DROP TRIGGER IF EXISTS trg_send_stock_alert_on_low_stock;
DROP TRIGGER IF EXISTS trg_archive_deleted_venta;
DROP TRIGGER IF EXISTS trg_validate_email_format_on_customer;
DROP TRIGGER IF EXISTS trg_validate_email_format_on_insert;
DROP TRIGGER IF EXISTS trg_validate_email_format_on_update;
DROP TRIGGER IF EXISTS trg_update_last_order_date_customer;
DROP TRIGGER IF EXISTS trg_prevent_self_referral;
DROP TRIGGER IF EXISTS trg_prevent_self_referral_update;
DROP TRIGGER IF EXISTS trg_log_permission_changes;
DROP TRIGGER IF EXISTS trg_assign_default_category_on_null;
DROP TRIGGER IF EXISTS trg_update_producto_count_in_categoria;
DROP TRIGGER IF EXISTS trg_update_producto_count_after_insert;
DROP TRIGGER IF EXISTS trg_update_producto_count_after_delete;


-- ==============================================================================
-- EJECUTABLES PREVIOS (Comentados para que no se ejecuten por accidente)
-- ==============================================================================

-- 1. Tabla de soporte para trg_audit_precio_producto_after_update
DROP TABLE IF EXISTS log_cambios_precio;
CREATE TABLE log_cambios_precio(
    id_log_cambios_precio INT AUTO_INCREMENT PRIMARY KEY,
    id_producto INT NOT NULL,
    precio_viejo DECIMAL (10,2),
    precio_nuevo DECIMAL(10,2),
    fecha_log TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

-- 5. Tabla de soporte para trg_log_new_customer_after_insert
DROP TABLE IF EXISTS logs_new_cliente;
CREATE TABLE logs_new_cliente(
    id_log INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    fecha_log TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);

-- 6. Modificaciones previas para trg_update_total_gastado_cliente
ALTER TABLE clientes ADD COLUMN total_gastado DECIMAL(12,2) DEFAULT 0;
UPDATE clientes c
SET total_gastado = (
    SELECT IFNULL(SUM(total), 0) 
    FROM ventas v 
    WHERE v.id_cliente = c.id_cliente
);

-- 7. Columna previa para trg_set_fecha_modificacion_producto
ALTER TABLE productos ADD COLUMN ultima_fecha_modificacion TIMESTAMP;

-- 11. Tabla de soporte para trg_log_order_status_change
DROP TABLE IF EXISTS log_cambio_estado;
CREATE TABLE log_cambio_estado(
    id_log_cambios_estado INT AUTO_INCREMENT PRIMARY KEY,
    id_venta INT NOT NULL,
    estado_viejo VARCHAR(100),
    estado_nuevo VARCHAR(100),
    fecha_log TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_venta) REFERENCES ventas(id_venta)
);

-- 13. Tabla de soporte para trg_send_stock_alert_on_low_stock
DROP TABLE IF EXISTS alerta_stock;
CREATE TABLE alerta_stock(
    id_alerta_stock INT AUTO_INCREMENT PRIMARY KEY,
    id_producto INT NOT NULL,
    stock_actual INT,
    mensaje VARCHAR(100),
    fecha_log TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

-- 14. Tabla de soporte para trg_archive_deleted_venta
DROP TABLE IF EXISTS ventas_archivadas;
CREATE TABLE ventas_archivadas (
    id_venta_archivada INT AUTO_INCREMENT PRIMARY KEY,
    id_venta INT NOT NULL,
    id_cliente INT NOT NULL,
    fecha_eliminacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('Pendiente de Pago', 'Procesando', 'Enviado', 'Entregado', 'Cancelado') NOT NULL,
    total DECIMAL(12,2)
);

-- 16. Columna previa para trg_update_last_order_date_customer
ALTER TABLE clientes ADD COLUMN ultima_fecha_compra TIMESTAMP;

-- 17. Columnas previas para trg_prevent_self_referral
ALTER TABLE clientes 
ADD COLUMN id_referidor INT DEFAULT NULL,
ADD CONSTRAINT fk_cliente_referidor FOREIGN KEY (id_referidor) REFERENCES clientes(id_cliente);

-- 19. Datos previos para trg_assign_default_category_on_null
INSERT INTO categorias(nombre,descripcion)
VALUES ('General','Cuando no se tiene categoria especifica, se coloca general');

-- 20. Modificaciones previas para trg_update_producto_count_in_categoria
ALTER TABLE categorias ADD COLUMN total_productos INT DEFAULT 0;
UPDATE categorias c
SET total_productos = (
    SELECT IFNULL(COUNT(*), 0) 
    FROM productos p
    WHERE p.id_categoria = c.id_categoria
);



-- ==============================================================================
-- CREACIÓN DE TRIGGERS
-- ==============================================================================

DELIMITER //

-- 1. trg_audit_precio_producto_after_update: Guarda un log de cambios de precios.
CREATE TRIGGER trg_audit_precio_producto_after_update
AFTER UPDATE ON productos
FOR EACH ROW
BEGIN
	IF NEW.precio != OLD.precio THEN
		INSERT INTO log_cambios_precio(id_producto,precio_viejo,precio_nuevo)
		VALUES (OLD.id_producto, OLD.precio, NEW.precio);
	END IF;
END //

-- 2. trg_check_stock_before_insert_venta: Verifica el stock antes de registrar una venta.
CREATE TRIGGER trg_check_stock_before_insert_venta
BEFORE INSERT ON detalle_ventas
FOR EACH ROW
BEGIN
	DECLARE v_stock_actual INT;
	SELECT stock INTO v_stock_actual FROM productos WHERE id_producto = NEW.id_producto;
	
	IF NEW.cantidad > v_stock_actual THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: No hay stock suficiente para realizar esta venta.';
    END IF;
END //

-- 3. trg_update_stock_after_insert_venta: Decrementa el stock después de una venta.
CREATE TRIGGER trg_update_stock_after_insert_venta
AFTER INSERT ON detalle_ventas
FOR EACH ROW
BEGIN
	UPDATE productos
	SET stock = stock - NEW.cantidad
	WHERE id_producto = NEW.id_producto;
END //

-- 4. trg_prevent_delete_categoria_with_products: Impide eliminar una categoría si tiene productos asociados.
CREATE TRIGGER trg_prevent_delete_categoria_with_products
BEFORE DELETE ON categorias
FOR EACH ROW
BEGIN
	IF EXISTS (SELECT 1 FROM productos WHERE id_categoria = OLD.id_categoria) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: No se puede eliminar la categoria porque tiene productos asociados.';
    END IF;
END //

-- 5. trg_log_new_customer_after_insert: Registra en una tabla de auditoría cada vez que se crea un nuevo cliente.
CREATE TRIGGER trg_log_new_customer_after_insert
AFTER INSERT ON clientes
FOR EACH ROW
BEGIN
	INSERT INTO logs_new_cliente(id_cliente) VALUES (NEW.id_cliente);
END //

-- 6. trg_update_total_gastado_cliente: Actualiza un campo total_gastado en la tabla clientes después de cada compra.
CREATE TRIGGER trg_update_total_gastado_cliente
AFTER UPDATE ON ventas
FOR EACH ROW
BEGIN
    IF NEW.estado = 'Entregado' AND OLD.estado != 'Entregado' THEN
	    UPDATE clientes
	    SET total_gastado = total_gastado + NEW.total
	    WHERE id_cliente = NEW.id_cliente;
    END IF;
END //

-- 7. trg_set_fecha_modificacion_producto: Actualiza automáticamente la fecha de última modificación de un producto.
CREATE TRIGGER trg_set_fecha_modificacion_producto
BEFORE UPDATE ON productos
FOR EACH ROW
BEGIN
	SET NEW.ultima_fecha_modificacion = NOW();
END //

-- 8. trg_prevent_negative_stock: Impide que el stock de un producto se actualice a un valor negativo.
CREATE TRIGGER trg_prevent_negative_stock
BEFORE UPDATE ON productos
FOR EACH ROW
BEGIN
	IF NEW.stock < 0 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El stock no puede ser un numero negativo';
	END IF;
END //

-- 9. trg_capitalize_nombre_cliente: Convierte a mayúscula la primera letra del nombre y apellido de un cliente al insertarlo.
CREATE TRIGGER trg_capitalize_nombre_cliente
BEFORE INSERT ON clientes
FOR EACH ROW
BEGIN
	SET NEW.nombre =CONCAT(UPPER(SUBSTRING(NEW.nombre, 1, 1)), LOWER(SUBSTRING(NEW.nombre, 2, LENGTH(NEW.nombre))));
	SET NEW.apellido = CONCAT(UPPER(SUBSTRING(NEW.apellido, 1, 1)), LOWER(SUBSTRING(NEW.apellido, 2, LENGTH(NEW.apellido))));
END //

-- 10. trg_recalculate_total_venta_on_detalle_change: Recalcula el total en la tabla ventas si se modifica un detalle_venta.
CREATE TRIGGER trg_recalculate_total_venta_on_detalle_change
AFTER UPDATE ON detalle_ventas
FOR EACH ROW
BEGIN
	UPDATE ventas 
	SET total = total - (OLD.cantidad * OLD.precio_unitario_congelado) + (NEW.cantidad * NEW.precio_unitario_congelado)
	WHERE OLD.id_venta = id_venta;
END //

-- 11. trg_log_order_status_change: Audita cada cambio de estado en un pedido (ej. de 'Procesando' a 'Enviado').
CREATE TRIGGER trg_log_order_status_change
AFTER UPDATE ON ventas
FOR EACH ROW
BEGIN
	IF OLD.estado != NEW.estado THEN
		INSERT INTO log_cambio_estado(id_venta,estado_viejo,estado_nuevo)
		VALUES (old.id_venta,old.estado,new.estado);
	END IF;
END //

-- 12. trg_prevent_price_zero_or_less: Impide que el precio de un producto se establezca en cero o un valor negativo.
CREATE TRIGGER trg_prevent_price_zero_or_less
BEFORE UPDATE ON productos
FOR EACH ROW
BEGIN
	IF NEW.precio <= 0 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El precio no puede ser cero o un numero negativo';
	END IF;
END //

-- 13. trg_send_stock_alert_on_low_stock: Inserta un registro en una tabla alertas si el stock baja de un umbral.
CREATE TRIGGER trg_send_stock_alert_on_low_stock
AFTER UPDATE ON productos
FOR EACH ROW
BEGIN
	IF NEW.stock <= 9 AND OLD.stock > 9 THEN
		INSERT INTO alerta_stock(id_producto,stock_actual,mensaje)
		VALUES (OLD.id_producto,NEW.stock,'Alerta: Producto demasiado bajo');
	END IF;
END //

-- 14. trg_archive_deleted_venta: Mueve una venta eliminada a una tabla de archivo en lugar de borrarla permanentemente.
CREATE TRIGGER trg_archive_deleted_venta
BEFORE DELETE ON ventas
FOR EACH ROW
BEGIN
	INSERT INTO ventas_archivadas(id_venta,id_cliente,estado,total)
	VALUES (OLD.id_venta,OLD.id_cliente,OLD.estado,OLD.total);
END //

-- 15. trg_validate_email_format_on_customer: Valida el formato del email antes de insertar o actualizar un cliente.
CREATE TRIGGER trg_validate_email_format_on_insert
BEFORE INSERT ON clientes
FOR EACH ROW
BEGIN
    IF NEW.email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: El formato del correo electrónico no es válido.';
    END IF;
END //

CREATE TRIGGER trg_validate_email_format_on_update
BEFORE UPDATE ON clientes
FOR EACH ROW
BEGIN
    IF NEW.email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: El formato del nuevo correo electrónico no es válido.';
    END IF;
END //

-- 16. trg_update_last_order_date_customer: Actualiza la fecha del último pedido en la tabla clientes.
CREATE TRIGGER trg_update_last_order_date_customer
AFTER INSERT ON ventas
FOR EACH ROW
BEGIN
	UPDATE clientes
	SET ultima_fecha_compra = NEW.fecha_venta
	WHERE id_cliente = NEW.id_cliente;
END //

-- 17. trg_prevent_self_referral: Impide que un cliente se referencie a sí mismo en un programa de referidos.
CREATE TRIGGER trg_prevent_self_referral
BEFORE INSERT ON clientes
FOR EACH ROW
BEGIN
    IF NEW.id_referidor IS NOT NULL AND NEW.id_referidor = NEW.id_cliente THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: Un cliente no puede referenciarse a sí mismo.';
    END IF;
END //

CREATE TRIGGER trg_prevent_self_referral_update
BEFORE UPDATE ON clientes
FOR EACH ROW
BEGIN
    IF NEW.id_referidor IS NOT NULL AND NEW.id_referidor = NEW.id_cliente THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: Un cliente no puede referenciarse a sí mismo.';
    END IF;
END //



-- 19. trg_assign_default_category_on_null: Asigna una categoría "General" si se inserta un producto sin categoría.
CREATE TRIGGER trg_assign_default_category_on_null
BEFORE INSERT ON productos
FOR EACH ROW
BEGIN
    IF NEW.id_categoria IS NULL THEN
        SET NEW.id_categoria = 6; 
    END IF;
END //

-- 20. trg_update_producto_count_in_categoria: Mantiene un contador de cuántos productos hay en cada categoría.
CREATE TRIGGER trg_update_producto_count_after_insert
AFTER INSERT ON productos
FOR EACH ROW
BEGIN
    UPDATE categorias
    SET total_productos = total_productos + 1
    WHERE id_categoria = NEW.id_categoria;
END //

CREATE TRIGGER trg_update_producto_count_after_delete
AFTER DELETE ON productos
FOR EACH ROW
BEGIN
    UPDATE categorias
    SET total_productos = total_productos - 1
    WHERE id_categoria = OLD.id_categoria;
END //

DELIMITER ;