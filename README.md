# Base de Datos de un E-commerce

Proyecto de base de datos en MySQL que modela el núcleo de una tienda en línea: catálogo de productos, categorías, proveedores, clientes y el ciclo completo de una venta (encabezado + detalle). Además de las tablas, el proyecto implementa consultas de análisis, funciones reutilizables, procedimientos transaccionales, triggers de integridad/auditoría, eventos programados y un esquema de roles y permisos.

## Integrantes

- Sebastián _(agrega aquí el resto del equipo si aplica)_

## Contenido

- [Entidades principales](#entidades-principales)
- [Estructura del repositorio](#estructura-del-repositorio)
- [Requisitos previos](#requisitos-previos)
- [Cómo ejecutar el proyecto](#cómo-ejecutar-el-proyecto)
- [Detalle de cada script](#detalle-de-cada-script)
- [Notas y decisiones de diseño](#notas-y-decisiones-de-diseño)

---

## Entidades principales

| Entidad | Descripción |
|---|---|
| `categorias` | Clasificación de los productos (Electrónica, Ropa, Hogar, etc.). |
| `proveedores` | Empresas que suministran los productos. |
| `clientes` | Usuarios registrados que realizan compras. |
| `productos` | Catálogo de artículos disponibles, con precio, costo, stock y SKU. |
| `ventas` | Encabezado de cada transacción (cliente, fecha, estado, total). |
| `detalle_ventas` | Líneas de cada venta: qué productos, cuántas unidades y a qué precio se vendieron (precio congelado al momento de la venta). |

**Relaciones:** una categoría tiene muchos productos; un proveedor suministra muchos productos; un cliente realiza muchas ventas; una venta puede incluir muchos productos y un producto puede estar en muchas ventas, relación resuelta a través de `detalle_ventas`.

## Estructura del repositorio

Todos los scripts `.sql` están en la raíz del repositorio. Cada uno contiene únicamente el código correspondiente a su nombre y puede identificarse por su prefijo numérico según el orden de ejecución.

```
Proyecto_Script.sql          # 1. Estructura de la base de datos
Proyecto_Inserts.sql         # 2. Datos de prueba
Proyecto_Funciones.sql       # 3. Funciones (UDFs)
Proyecto_Procedimientos.sql  # 4. Procedimientos almacenados
Proyecto_Triggers.sql        # 5. Triggers
Proyecto_Eventos.sql         # 6. Eventos programados
Proyecto_Consultas.sql       # 7. Consultas de análisis y reporteo
Proyecto_Seguridad.sql       # 8. Roles, usuarios y permisos
```

## Requisitos previos

- MySQL 8.0 o superior (se usan `ROLE`, `NTILE()`, `REGEXP_LIKE`, `CHECK` constraints y eventos programados).
- Un cliente para ejecutar los scripts: [DBeaver](https://dbeaver.io/), MySQL Workbench, o la terminal (`mysql`).
- Permisos de administrador en el servidor (se crean bases de datos, usuarios, roles y se activa el *event scheduler*).

## Cómo ejecutar el proyecto

1. Clona el repositorio.
2. Conéctate a tu servidor MySQL con un usuario con privilegios de administrador.
3. Ejecuta los archivos **en este orden exacto** (cada uno depende de que el anterior ya se haya ejecutado):

   1. `Proyecto_Script.sql` — crea la base de datos `proyectosql` y las 6 tablas.
   2. `Proyecto_Inserts.sql` — carga los datos de prueba.
   3. `Proyecto_Funciones.sql` — crea las funciones de negocio.
   4. `Proyecto_Procedimientos.sql` — crea los procedimientos almacenados.
   5. `Proyecto_Triggers.sql` — crea las tablas de soporte (logs, auditoría) y los triggers.
   6. `Proyecto_Eventos.sql` — crea las tablas de reportes y los eventos programados, y activa el *event scheduler*.
   7. `Proyecto_Consultas.sql` — no crea objetos, solo contiene las consultas de análisis (se pueden ejecutar en cualquier momento después del paso 2).
   8. `Proyecto_Seguridad.sql` — crea roles, usuarios y asigna permisos sobre los objetos ya existentes.

   Si usas DBeaver o MySQL Workbench, puedes abrir cada archivo y ejecutarlo completo (`Ctrl+A` → ejecutar) en el orden indicado. Desde la terminal:

   ```bash
   mysql -u root -p < Proyecto_Script.sql
   mysql -u root -p < Proyecto_Inserts.sql
   mysql -u root -p < Proyecto_Funciones.sql
   mysql -u root -p < Proyecto_Procedimientos.sql
   mysql -u root -p < Proyecto_Triggers.sql
   mysql -u root -p < Proyecto_Eventos.sql
   mysql -u root -p < Proyecto_Consultas.sql
   mysql -u root -p < Proyecto_Seguridad.sql
   ```

4. Verifica que todo se ejecutó sin errores. El proyecto fue probado ejecutando estos 8 archivos de forma consecutiva sobre una base de datos nueva.

> ⚠️ `Proyecto_Seguridad.sql` crea usuarios de MySQL (`admin_user`, `marketing_user`, `inventory_user`, `support_user`) con contraseñas de ejemplo definidas en el propio script, y elimina el acceso remoto del usuario `root`. Revisa ese archivo antes de ejecutarlo si vas a correrlo en un entorno compartido.

## Detalle de cada script

### 1. `Proyecto_Script.sql`
Crea la base de datos `proyectosql` y las 6 tablas principales, con sus llaves primarias, llaves foráneas y restricciones (`CHECK`, `UNIQUE`, `NOT NULL`).

### 2. `Proyecto_Inserts.sql`
Datos de prueba: 5 categorías, 5 proveedores, 10 clientes (con fechas de registro escalonadas para análisis de cohortes), 20 productos y 15 ventas con su detalle. Los totales de cada venta coinciden exactamente con la suma de sus líneas de detalle.

### 3. `Proyecto_Funciones.sql`
20 funciones definidas por el usuario que encapsulan lógica de negocio reutilizable: cálculo de totales, verificación de stock, validación de email y contraseña, estado de lealtad del cliente, generación de SKU, cálculo de IVA, entre otras.

### 4. `Proyecto_Procedimientos.sql`
Procedimientos almacenados para operaciones transaccionales y de negocio: registrar una venta, agregar productos, ajustar stock con auditoría, fusionar cuentas de cliente, búsqueda avanzada de productos, dashboard de KPIs, entre otros. Los que modifican varias tablas usan `START TRANSACTION` / `COMMIT` con manejo de errores (`EXIT HANDLER`) para revertir cambios si algo falla.

### 5. `Proyecto_Triggers.sql`
Crea primero las tablas de soporte necesarias (logs de auditoría, historial de precios, alertas de stock, ventas archivadas) y luego los triggers: control de stock antes/después de una venta, auditoría de cambios de precio y de estado de pedido, validación de formato de email, prevención de auto-referidos, contador de productos por categoría, entre otros.

### 6. `Proyecto_Eventos.sql`
Crea las tablas de reportes necesarias y 10 eventos programados que automatizan tareas de mantenimiento y negocio: reportes de ventas (semanal y diario), desactivación de promociones expiradas, recálculo del nivel de lealtad, lista de reabastecimiento, reconstrucción de índices, suspensión de cuentas inactivas y verificación de inconsistencias de datos. El script activa el *event scheduler* al final para que los eventos se ejecuten automáticamente según su programación.

### 7. `Proyecto_Consultas.sql`
Consultas de análisis y reporteo sobre los datos ya cargados: top de productos más vendidos, productos con bajas ventas, clientes VIP (LTV), ventas mensuales, crecimiento de clientes por trimestre, tasa de recompra, productos comprados juntos con frecuencia, productos que necesitan reabastecimiento y margen de beneficio por producto.

### 8. `Proyecto_Seguridad.sql`
Define 7 roles con distintos niveles de acceso (administrador, marketing, analista de datos, inventario, atención al cliente, auditor financiero, visitante), crea 4 usuarios y les asigna su rol correspondiente, y aplica restricciones adicionales (revocar permisos sensibles, política de contraseñas, límite de consultas por hora, bloqueo de acceso remoto para `root`).

## Notas y decisiones de diseño

- **Precio congelado en las ventas:** `detalle_ventas.precio_unitario_congelado` guarda el precio del producto al momento de la venta, independiente del precio actual en `productos`, para no alterar el historial si el precio cambia después.
- **Reabastecimiento:** como el esquema no incluye un umbral mínimo de stock por producto, la consulta de reabastecimiento usa un valor fijo de referencia.
- **Triggers de un solo evento:** MySQL no permite que un mismo trigger responda a dos eventos distintos (por ejemplo, `INSERT` y `UPDATE`), así que la validación de email y la prevención de auto-referidos están implementadas como dos triggers independientes cada una.
- **Orden de `Proyecto_Seguridad.sql` al final:** se ejecuta después de todos los demás porque varios de sus permisos apuntan a objetos (tablas de log, vistas, procedimientos) que solo existen una vez que el resto del proyecto ya se creó.
