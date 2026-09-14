CREATE DATABASE proyectosql;
use proyectosql;


-- 1. Entidad: Categorías (Tabla Padre)
CREATE TABLE Categorias (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT
);

-- 2. Entidad: Proveedores (Tabla Padre)
CREATE TABLE Proveedores (
    id_proveedor INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    email_contacto VARCHAR(150) UNIQUE,
    telefono_contacto VARCHAR(50)
);

-- 3. Entidad: Clientes (Tabla Padre)
CREATE TABLE Clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    contraseña VARCHAR(255) NOT NULL, -- Longitud suficiente para el hash
    direccion_envio TEXT,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Entidad: Productos (Tabla Hija de Categorías y Proveedores)
CREATE TABLE Productos (
    id_producto INT AUTO_INCREMENT PRIMARY KEY,
    id_categoria INT NOT NULL,
    id_proveedor INT NOT NULL,
    nombre VARCHAR(150) NOT NULL UNIQUE,
    descripcion TEXT,
    precio DECIMAL(10,2) NOT NULL CHECK (precio > 0),
    costo DECIMAL(10,2) NOT NULL CHECK (costo >= 0),
    stock INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
    sku VARCHAR(50) NOT NULL UNIQUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (id_categoria) REFERENCES Categorias(id_categoria),
    FOREIGN KEY (id_proveedor) REFERENCES Proveedores(id_proveedor)
);

-- 5. Entidad: Ventas (Tabla Hija de Clientes)
CREATE TABLE Ventas (
    id_venta INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    fecha_venta TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('Pendiente de Pago', 'Procesando', 'Enviado', 'Entregado', 'Cancelado') NOT NULL,
    total DECIMAL(12,2) DEFAULT 0.00, -- Se actualizará mediante triggers o SPs
    FOREIGN KEY (id_cliente) REFERENCES Clientes(id_cliente)
);

-- 6. Entidad: Detalle de Ventas (Tabla Puente / Hija de Ventas y Productos)
CREATE TABLE Detalle_Ventas (
    id_detalle INT AUTO_INCREMENT PRIMARY KEY,
    id_venta INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    precio_unitario_congelado DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_venta) REFERENCES Ventas(id_venta) ON DELETE CASCADE,
    FOREIGN KEY (id_producto) REFERENCES Productos(id_producto)
);






