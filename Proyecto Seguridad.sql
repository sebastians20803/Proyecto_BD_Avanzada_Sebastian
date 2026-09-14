-- ==============================================================================
-- 06_Seguridad.sql
-- Gestión de Roles, Usuarios y Permisos de Acceso
-- ==============================================================================


-- 6 Seguridad.

-- 1. Eliminar usuarios si ya existen
DROP USER IF EXISTS 'admin_user'@'%', 'marketing_user'@'%', 'inventory_user'@'%', 'support_user'@'%';

-- 2. Eliminar roles si ya existen
DROP ROLE IF EXISTS 'Administrador_Sistema', 'Gerente_Marketing', 'Analista_Datos', 'Empleado_Inventario', 'Atencion_Cliente', 'Auditor_Financiero', 'Visitante';


-- 6.1 Crear el rol Administrador_Sistema con todos los privilegios.

CREATE ROLE 'Administrador_Sistema';
GRANT ALL PRIVILEGES ON proyectosql.* TO 'Administrador_Sistema';

-- 6.2 Crear el rol Gerente_Marketing con acceso de solo lectura a ventas y clientes.

CREATE ROLE 'Gerente_Marketing';
GRANT SELECT ON proyectosql.ventas TO 'Gerente_Marketing';
GRANT SELECT ON proyectosql.clientes TO 'Gerente_Marketing';

-- 6.3 Crear el rol Analista_Datos con acceso de solo lectura a todas las tablas, excepto a las de auditoría.

CREATE ROLE 'Analista_Datos';
GRANT SELECT ON proyectosql.clientes TO 'Analista_Datos';
GRANT SELECT ON proyectosql.productos TO 'Analista_Datos';
GRANT SELECT ON proyectosql.categorias TO 'Analista_Datos';
GRANT SELECT ON proyectosql.ventas TO 'Analista_Datos';
GRANT SELECT ON proyectosql.detalle_ventas TO 'Analista_Datos';

-- 6.4 Crear el rol Empleado_Inventario que solo pueda modificar la tabla productos (stock y ubicación).

CREATE ROLE 'Empleado_Inventario';
GRANT SELECT ON proyectosql.productos TO 'Empleado_Inventario';
GRANT UPDATE(stock, id_categoria) ON proyectosql.productos TO 'Empleado_Inventario';

-- 6.5 Crear el rol Atencion_Cliente que pueda ver clientes y ventas, pero no modificar precios.

CREATE ROLE 'Atencion_Cliente';
GRANT SELECT ON proyectosql.clientes TO 'Atencion_Cliente';
GRANT SELECT ON proyectosql.ventas TO 'Atencion_Cliente';

-- 6.6 Crear el rol Auditor_Financiero con acceso de solo lectura a ventas, productos y logs de precios.

CREATE ROLE 'Auditor_Financiero';
GRANT SELECT ON proyectosql.productos TO 'Auditor_Financiero';
GRANT SELECT ON proyectosql.ventas TO 'Auditor_Financiero';
GRANT SELECT ON proyectosql.logs_precios TO 'Auditor_Financiero'; 

-- 6.7 Crear un usuario admin_user y asignarle el rol de administrador.

CREATE USER 'admin_user'@'%' IDENTIFIED BY 'Admin123';
GRANT 'Administrador_Sistema' TO 'admin_user'@'%';
SET DEFAULT ROLE 'Administrador_Sistema' TO 'admin_user'@'%';

-- 6.8 Crear un usuario marketing_user y asignarle el rol de marketing.

CREATE USER 'marketing_user'@'%' IDENTIFIED BY 'Marketing123';
GRANT 'Gerente_Marketing' TO 'marketing_user'@'%';
SET DEFAULT ROLE 'Gerente_Marketing' TO 'marketing_user'@'%';

-- 6.9 Crear un usuario inventory_user y asignarle el rol de inventario.

CREATE USER 'inventory_user'@'%' IDENTIFIED BY 'Inventory123';
GRANT 'Empleado_Inventario' TO 'inventory_user'@'%';
SET DEFAULT ROLE 'Empleado_Inventario' TO 'inventory_user'@'%';

-- 6.10 Crear un usuario support_user y asignarle el rol de atención al cliente.

CREATE USER 'support_user'@'%' IDENTIFIED BY 'Support123';
GRANT 'Atencion_Cliente' TO 'support_user'@'%';
SET DEFAULT ROLE 'Atencion_Cliente' TO 'support_user'@'%';


-- 6.11 Impedir que el rol Analista_Datos pueda ejecutar comandos DELETE o TRUNCATE.

REVOKE DELETE, DROP ON proyectosql.* FROM 'Analista_Datos';

-- 6.12 Otorgar al rol Gerente_Marketing permiso para ejecutar procedimientos almacenados de reportes de marketing.

GRANT EXECUTE ON PROCEDURE proyectosql.sp_Reporte_Marketing TO 'Gerente_Marketing';

-- 6.13 Crear una vista v_info_clientes_basica que oculte información sensible y dar acceso a ella al rol Atencion_Cliente.

CREATE VIEW v_info_clientes_basica AS
SELECT  nombre,
		apellido,
		email,
		fecha_registro
FROM clientes;

GRANT SELECT ON proyectosql.v_info_clientes_basica TO 'Atencion_Cliente';

-- 6.14 Revocar el permiso de UPDATE sobre la columna precio de la tabla productos al rol Empleado_Inventario.

REVOKE UPDATE (precio) ON proyectosql.productos FROM 'Empleado_Inventario';


-- 6.15 Implementar una política de contraseñas seguras para todos los usuarios.

SET GLOBAL validate_password.policy = 'MEDIUM';
SET GLOBAL validate_password.length = 8;

-- 6.16 Asegurar que el usuario root no pueda ser usado desde conexiones remotas.

DROP USER IF EXISTS 'root'@'%';
FLUSH PRIVILEGES;

-- 6.17 Crear un rol Visitante que solo pueda ver la tabla productos.

CREATE ROLE 'Visitante';
GRANT SELECT ON proyectosql.productos TO 'Visitante';

-- 6.18 Limitar el número de consultas por hora para el rol Analista_Datos para evitar sobrecarga.


ALTER ROLE 'Analista_Datos'@'%' WITH MAX_QUERIES_PER_HOUR 100;


-- 6.19 Asegurar que los usuarios solo puedan ver las ventas de la sucursal a la que pertenecen (requiere añadir id_sucursal).


-- 6.20 Auditar todos los intentos de inicio de sesión fallidos en la base de datos.