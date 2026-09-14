use proyectosql; 


-- 4. Consultas Avanzadas (Análisis y Reporteo)


-- 4.1 Top 10 Productos Más Vendidos: Generar un ranking con los 10 
-- productos que han generado más ingresos.

SELECT 
	p.nombre as producto,
	sum(dv.cantidad*dv.precio_unitario_congelado) as total_ventas
FROM productos p
INNER JOIN detalle_ventas dv ON p.id_producto = dv.id_producto
INNER JOIN ventas v ON dv.id_venta = v.id_venta
WHERE v.estado != 'Cancelado'
GROUP BY p.nombre
ORDER BY total_ventas DESC
LIMIT 10;    



-- 4.2 Productos con Bajas Ventas: Identificar los productos en el 10% 
-- inferior de ventas para considerar su descontinuación.

WITH RankingVentas AS (
    SELECT 
        p.id_producto,
        p.nombre AS producto,
        IFNULL(SUM(dv.cantidad * dv.precio_unitario_congelado), 0) AS total_ventas,
        -- Dividimos los resultados en 10 grupos ordenados de menor a mayor venta
        NTILE(10) OVER (ORDER BY IFNULL(SUM(dv.cantidad * dv.precio_unitario_congelado), 0) ASC) AS grupo_decil
        
    FROM productos p
    LEFT JOIN detalle_ventas dv ON p.id_producto = dv.id_producto
    LEFT JOIN ventas v ON dv.id_venta = v.id_venta 
    WHERE v.estado != 'Cancelado'
    GROUP BY p.id_producto, p.nombre
)
-- Filtro solo el grupo 1 (que representa el 10% con las ventas más bajas)
SELECT 
    producto, 
    total_ventas 
FROM RankingVentas
WHERE grupo_decil = 1;




-- 4.3 Clientes VIP: Listar los 5 clientes con el mayor valor de vida (LTV), 
-- basado en su gasto total histórico.

SELECT 
	CONCAT(c.nombre,' ',c.apellido) as cliente,
	SUM(v.total) as LTV
	FROM clientes c
	INNER JOIN ventas v ON c.id_cliente = v.id_cliente
	WHERE v.estado != 'Cancelado'
	GROUP BY c.id_cliente
	ORDER BY LTV DESC 
	LIMIT 5;

-- 4.4 Análisis de Ventas Mensuales: Mostrar las ventas totales agrupadas 
-- por mes y año.

SELECT 
    YEAR(v.fecha_venta) AS anio,
    MONTH(v.fecha_venta) AS mes,
    SUM(v.total) AS total_ventas
FROM ventas v
WHERE v.estado != 'Cancelado'
GROUP BY YEAR(v.fecha_venta), MONTH(v.fecha_venta)
ORDER BY anio DESC, mes DESC;

-- 4.5 Crecimiento de Clientes: Calcular el número de nuevos clientes 
-- registrados por trimestre.

SELECT 
    CONCAT(YEAR(fecha_registro), '-Q', QUARTER(fecha_registro)) AS periodo,
    COUNT(*) AS nuevos_clientes
FROM clientes
GROUP BY CONCAT(YEAR(fecha_registro), '-Q', QUARTER(fecha_registro))
ORDER BY MAX(fecha_registro) DESC;

-- 4.6 Tasa de Compra Repetida: Determinar qué porcentaje de clientes ha 
-- realizado más de una compra.

SELECT 
    (SUM(total_compras > 1) / COUNT(*)) * 100 AS porcentaje_recompra
FROM (
    SELECT 
        id_cliente, 
        COUNT(*) AS total_compras
    FROM ventas
    WHERE estado != 'Cancelado'
    GROUP BY id_cliente
) AS tabla_temporal;

-- 4.7 Productos Comprados Juntos Frecuentemente: Identificar pares de 
-- productos que a menudo se compran en la misma transacción.

SELECT 
    p1.nombre AS producto_A,
    p2.nombre AS producto_B,
    COUNT(*) AS veces_comprados_juntos
FROM detalle_ventas dv1
INNER JOIN detalle_ventas dv2 
    ON dv1.id_venta = dv2.id_venta         -- Magia 1: Aseguramos que sea el mismo carrito
    AND dv1.id_producto < dv2.id_producto  -- Magia 2: Evita que el producto se empareje consigo mismo o salgan pares repetidos al revés
INNER JOIN productos p1 ON dv1.id_producto = p1.id_producto
INNER JOIN productos p2 ON dv2.id_producto = p2.id_producto
GROUP BY p1.nombre, p2.nombre
ORDER BY VECES_COMPRADOS_JUNTOS DESC;


-- 4.8 Rotación de Inventario: Calcular la tasa de rotación de stock para 
-- cada categoría de producto.


-- 4.9 Productos que Necesitan Reabastecimiento: Listar productos cuyo stock 
-- actual está por debajo de su umbral mínimo.


-- 4.10 Análisis de Carrito Abandonado (Simulado): Identificar clientes que 
-- agregaron productos pero no completaron una venta en un período determinado.


-- 4.11 Rendimiento de Proveedores: Clasificar a los proveedores según el 
-- volumen de ventas de sus productos.


-- 4.12 Análisis Geográfico de Ventas: Agrupar las ventas por ciudad o región 
-- del cliente.


-- 4.13 Ventas por Hora del Día: Determinar las horas pico de compras para 
-- optimizar campañas de marketing.


-- 4.14 Impacto de Promociones: Comparar las ventas de un producto antes, 
-- durante y después de una campaña de descuento.


-- 4.15 Análisis de Cohort: Analizar la retención de clientes mes a mes 
-- desde su primera compra.


-- 4.16 Margen de Beneficio por Producto: Calcular el margen de beneficio 
-- para cada producto (requiere añadir un campo costo a la tabla productos).


-- 4.17 Tiempo Promedio Entre Compras: Calcular el tiempo medio que tarda un 
-- cliente en volver a comprar.


-- 4.18 Productos Más Vistos vs. Comprados: Comparar los productos más 
-- visitados con los más comprados.


-- 4.19 Segmentación de Clientes (RFM): Clasificar a los clientes en 
-- segmentos (Recencia, Frecuencia, Monetario).


-- 4.20 Predicción de Demanda Simple: Utilizar datos de ventas pasadas para 
-- proyectar las ventas del próximo mes para una categoría específica.

